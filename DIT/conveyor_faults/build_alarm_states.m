function S = build_alarm_states(res, feat, cal, p)
%BUILD_ALARM_STATES Build persistent (until recovery) alarm states on window centers.
%
% Produces continuous-ish boolean states for residual families that are
% naturally sparse (trav/dir) or noisy window-to-window (tick).
%
% States are updated only when new evidence arrives:
% - tick: per window center value with hysteresis
% - trav: updated on each traversal residual; held until a "good" traversal occurs
% - dir: updated on each direction-residual event; held until a "good" event occurs
%
% NaNs are not discarded; they are surfaced as *_nan flags.

if nargin < 4, p = struct(); end
p = conveyor_alarm_defaults(p);

S = struct();

% Time base
if nargin < 2 || ~isstruct(feat) || ~isfield(feat,'win_center_s')
    error('build_alarm_states:MissingFeat', 'feat.win_center_s is required.');
end

S.t_s = feat.win_center_s(:);
nt = numel(S.t_s);

% Ignore horizon: use same definition as extract_residual_events
t_ignore = p.t_ignore_s;
if nargin >= 3 && isstruct(cal) && isfield(cal,'T12_LR') && isfield(cal,'T12_RL')
    T12 = [cal.T12_LR, cal.T12_RL];
    T12 = T12(isfinite(T12) & T12 > 0);
    if ~isempty(T12)
        t_ignore = max(t_ignore, 1.5 * max(T12));
    end
end

S.t_ignore_s = t_ignore;
S.mask = (S.t_s >= t_ignore);

% Hysteresis thresholds (explicitly defined in conveyor_alarm_defaults)
thr_tick_on     = p.thr_r_tick;
thr_tick_hi_on  = p.thr_r_tick_hi;
thr_trav_on     = p.thr_r_trav;
thr_trav_hi_on  = p.thr_r_trav_hi;

thr_tick_off    = p.thr_r_tick_off;
thr_tick_hi_off = p.thr_r_tick_hi_off;
thr_trav_off    = p.thr_r_trav_off;
thr_trav_hi_off = p.thr_r_trav_hi_off;

% -----------------------
% Tick (per window)
% -----------------------
S.tick_val = nan(nt,1);
S.tick_nan = true(nt,1);
S.tick_state = false(nt,1);
S.tick_hi_state = false(nt,1);

if isfield(res,'r_tick_t_s') && isfield(res,'r_tick')
    % assume aligned to win centers
    x = res.r_tick(:);
    if numel(x) == nt
        S.tick_val = x;
        S.tick_nan = ~isfinite(x);

        st = false;
        stHi = false;
        for i = 1:nt
            if ~S.mask(i)
                % Do not consider anything before ignore horizon.
                S.tick_state(i) = false;
                S.tick_hi_state(i) = false;
                S.tick_nan(i) = false;
                S.tick_val(i) = NaN;
                continue;
            end
            xi = x(i);
            if ~isfinite(xi)
                % keep state, but expose NaN in S.tick_nan
                S.tick_state(i) = st;
                S.tick_hi_state(i) = stHi;
                continue;
            end

            % update HI state first
            if ~stHi
                stHi = xi >= thr_tick_hi_on;
            else
                stHi = xi >= thr_tick_hi_off;
            end

            % update normal tick state
            if ~st
                st = xi >= thr_tick_on;
            else
                st = xi >= thr_tick_off;
            end

            S.tick_hi_state(i) = stHi;
            S.tick_state(i) = st;
        end
    end
end

% -----------------------
% Trav (sparse events -> held until recovery event)
% -----------------------
S.trav_latest = nan(nt,1);
S.trav_known  = false(nt,1);
S.trav_state  = false(nt,1);
S.trav_hi_state = false(nt,1);

[t_trav, x_trav] = collect_trav_events(res);
if ~isempty(t_trav)
    ok = isfinite(t_trav) & (t_trav >= t_ignore);
    t_trav = t_trav(ok);
    x_trav = x_trav(ok);
    [t_trav, ord] = sort(t_trav(:));
    x_trav = x_trav(ord);

    k = 1;
    lastX = NaN;
    st = false;
    stHi = false;

    for i = 1:nt
        ti = S.t_s(i);
        if ~S.mask(i)
            S.trav_state(i) = false;
            S.trav_hi_state(i) = false;
            continue;
        end
        while k <= numel(t_trav) && t_trav(k) <= ti
            if isfinite(x_trav(k))
                lastX = x_trav(k);
                % Update states only when we got a new finite traversal residual
                if ~stHi
                    stHi = lastX >= thr_trav_hi_on;
                else
                    stHi = lastX >= thr_trav_hi_off;
                end

                if ~st
                    st = lastX >= thr_trav_on;
                else
                    st = lastX >= thr_trav_off;
                end
            end
            k = k + 1;
        end

        if isfinite(lastX)
            S.trav_latest(i) = lastX;
            S.trav_known(i) = true;
        end
        S.trav_hi_state(i) = stHi;
        S.trav_state(i) = st;
    end
end

% -----------------------
% Dir (sparse events -> held until recovery event)
% -----------------------
S.dir_latest = nan(nt,1);
S.dir_known  = false(nt,1);
S.dir_nan_event_latest = false(nt,1);
S.dir_state = false(nt,1);

[t_dir, x_dir] = collect_dir_events(res);
if ~isempty(t_dir)
    ok = isfinite(t_dir) & (t_dir >= t_ignore);
    t_dir = t_dir(ok);
    x_dir = x_dir(ok);
    [t_dir, ord] = sort(t_dir(:));
    x_dir = x_dir(ord);

    k = 1;
    lastFinite = NaN;
    lastWasNan = false;
    st = false;

    for i = 1:nt
        ti = S.t_s(i);
        if ~S.mask(i)
            S.dir_state(i) = false;
            S.dir_nan_event_latest(i) = false;
            continue;
        end
        while k <= numel(t_dir) && t_dir(k) <= ti
            if isfinite(x_dir(k))
                lastFinite = x_dir(k);
                lastWasNan = false;
                % dir residual is binary {0,1}
                st = (lastFinite > 0.5);
            else
                % A NaN here means "not applicable" under direction gating.
                % We expose it; we do NOT force st=1.
                lastWasNan = true;
            end
            k = k + 1;
        end

        if isfinite(lastFinite)
            S.dir_latest(i) = lastFinite;
            S.dir_known(i) = true;
        end
        S.dir_nan_event_latest(i) = lastWasNan;
        S.dir_state(i) = st;
    end
end

% -----------------------
% Disconnected residuals (already on window centers)
% -----------------------
S.s1_disc = get_bin_on_grid(res, 'r_s1_disc', nt) & S.mask;
S.s2_disc = get_bin_on_grid(res, 'r_s2_disc', nt) & S.mask;
S.tick_disc = get_bin_on_grid(res, 'r_tick_disc', nt) & S.mask;
S.motor_disc = get_bin_on_grid(res, 'r_motor_disc', nt) & S.mask;
S.lamps_disc = get_bin_on_grid(res, 'r_lamps_disc', nt) & S.mask;

end

function b = get_bin_on_grid(res, name, nt)
% Pull a {0,1} residual on window centers to a logical vector.
b = false(nt,1);
tField = [name '_t_s'];
if isfield(res, name) && isfield(res, tField)
    x = res.(name);
    if numel(x) == nt
        b = (x(:) > 0.5) & isfinite(x(:));
    end
end
end

function [t_trav, x_trav] = collect_trav_events(res)
% Collect traversal residual events from LR/RL.
t_trav = []; x_trav = [];
if isfield(res,'LR') && isstruct(res.LR) && isfield(res.LR,'t_start_s') && isfield(res.LR,'r_trav')
    t_trav = [t_trav; res.LR.t_start_s(:)];
    x_trav = [x_trav; res.LR.r_trav(:)];
end
if isfield(res,'RL') && isstruct(res.RL) && isfield(res.RL,'t_start_s') && isfield(res.RL,'r_trav')
    t_trav = [t_trav; res.RL.t_start_s(:)];
    x_trav = [x_trav; res.RL.r_trav(:)];
end
end

function [t_dir, x_dir] = collect_dir_events(res)
% Collect direction residual events from S1/S2 event streams.
t_dir = []; x_dir = [];
if isfield(res,'r_dir_S1_t_s') && isfield(res,'r_dir_S1')
    t_dir = [t_dir; res.r_dir_S1_t_s(:)];
    x_dir = [x_dir; res.r_dir_S1(:)];
end
if isfield(res,'r_dir_S2_t_s') && isfield(res,'r_dir_S2')
    t_dir = [t_dir; res.r_dir_S2_t_s(:)];
    x_dir = [x_dir; res.r_dir_S2(:)];
end
end
