function plot_all_residuals(res, feat, titlePrefix, cal, p)
%PLOT_ALL_RESIDUALS Plot all residuals available in calc_residuals output.
%
%   plot_all_residuals(res, feat, titlePrefix)
%
% This function produces figures for the current residual set.
% It plots the core residuals (r_tick, r_trav, r_dir) and then scans for any
% other fields starting with "r_" (including *_disc) and plots them.
%
% Legacy residual plots (r_io_*, r_pwr) are intentionally not shown here.

if nargin < 3, titlePrefix = ''; end
if nargin < 4, cal = struct(); end
if nargin < 5, p = struct(); end

p = conveyor_alarm_defaults(p);

% Compute ignore horizon consistent with extract_residual_events
t_ignore = p.t_ignore_s;
if isstruct(cal) && isfield(cal,'T12_LR') && isfield(cal,'T12_RL')
    T12 = [cal.T12_LR, cal.T12_RL];
    T12 = T12(isfinite(T12) & T12 > 0);
    if ~isempty(T12)
        t_ignore = max(t_ignore, 1.5 * max(T12));
    end
end

handled = containers.Map('KeyType','char','ValueType','logical');

    function t = mkTitle(s)
        if isempty(titlePrefix)
            t = s;
        else
            t = sprintf('%s: %s', titlePrefix, s);
        end
    end

    function markHandled(name)
        if ~isKey(handled, name)
            handled(name) = true;
        end
    end

    function [tt, xx] = applyIgnore(tt, xx)
        if isempty(tt) || isempty(xx)
            tt = []; xx = [];
            return;
        end
        tt = tt(:); xx = xx(:);
        ok = isfinite(tt) & isfinite(xx) & (tt >= t_ignore);
        tt = tt(ok);
        xx = xx(ok);
    end

    function res2 = filteredResForEventPlots(resIn)
        res2 = resIn;
        % Filter traversal event lists
        if isfield(res2,'LR') && isstruct(res2.LR) && isfield(res2.LR,'t_start_s') && isfield(res2.LR,'r_trav')
            [tLR, xLR] = applyIgnore(res2.LR.t_start_s, res2.LR.r_trav);
            res2.LR.t_start_s = tLR;
            res2.LR.r_trav = xLR;
        end
        if isfield(res2,'RL') && isstruct(res2.RL) && isfield(res2.RL,'t_start_s') && isfield(res2.RL,'r_trav')
            [tRL, xRL] = applyIgnore(res2.RL.t_start_s, res2.RL.r_trav);
            res2.RL.t_start_s = tRL;
            res2.RL.r_trav = xRL;
        end
        % Filter direction event lists
        if isfield(res2,'r_dir_S1_t_s') && isfield(res2,'r_dir_S1')
            [t1, x1] = applyIgnore(res2.r_dir_S1_t_s, res2.r_dir_S1);
            res2.r_dir_S1_t_s = t1;
            res2.r_dir_S1 = x1;
        end
        if isfield(res2,'r_dir_S2_t_s') && isfield(res2,'r_dir_S2')
            [t2, x2] = applyIgnore(res2.r_dir_S2_t_s, res2.r_dir_S2);
            res2.r_dir_S2_t_s = t2;
            res2.r_dir_S2 = x2;
        end
    end

% -----------------------
% r_tick
% -----------------------
if isfield(res,'r_tick')
    t_tick = [];
    if isfield(res,'r_tick_t_s')
        t_tick = res.r_tick_t_s;
    elseif nargin >= 2 && isfield(feat,'win_center_s')
        t_tick = feat.win_center_s;
    end

    if ~isempty(t_tick) && ~isempty(res.r_tick)
        [t_tick, x_tick] = applyIgnore(t_tick, res.r_tick);
        if isempty(t_tick), x_tick = []; end
    else
        x_tick = [];
    end

    if ~isempty(t_tick) && ~isempty(x_tick)
        figure;
        plot(t_tick, x_tick); grid on;
        xlabel('t [s]'); ylabel('r_{tick}');
        title(mkTitle('r_{tick}'));
        markHandled('r_tick');
        markHandled('r_tick_t_s');
    end
end

% -----------------------
% r_trav
% -----------------------
resEv = filteredResForEventPlots(res);
figure;
[h, lab] = plot_rtrav(resEv);
grid on; xlabel('t [s]'); ylabel('r_{trav}');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title(mkTitle('r_{trav} events'));
markHandled('LR');
markHandled('RL');

% -----------------------
% r_dir
% -----------------------
figure;
[h, lab] = plot_rdir(resEv);
grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title(mkTitle('r_{dir} events'));
markHandled('r_dir_S1');
markHandled('r_dir_S2');
markHandled('r_dir_S1_t_s');
markHandled('r_dir_S2_t_s');

% -----------------------
% sensors disconnected
% -----------------------
if isfield(res,'r_s1_disc_t_s') && isfield(res,'r_s1_disc') && ~isempty(res.r_s1_disc_t_s)
    [t1, x1] = applyIgnore(res.r_s1_disc_t_s, double(res.r_s1_disc));
    figure;
    plot(t1, x1); grid on;
    xlabel('t [s]'); ylabel('r_{s1\_disc}');
    title(mkTitle('r_{s1\_disc} (0/1)'));
    markHandled('r_s1_disc');
    markHandled('r_s1_disc_t_s');
end

if isfield(res,'r_s2_disc_t_s') && isfield(res,'r_s2_disc') && ~isempty(res.r_s2_disc_t_s)
    [t2, x2] = applyIgnore(res.r_s2_disc_t_s, double(res.r_s2_disc));
    figure;
    plot(t2, x2); grid on;
    xlabel('t [s]'); ylabel('r_{s2\_disc}');
    title(mkTitle('r_{s2\_disc} (0/1)'));
    markHandled('r_s2_disc');
    markHandled('r_s2_disc_t_s');
end

% -----------------------
% Scan and plot remaining r_* residuals (excluding legacy)
% -----------------------
legacyPrefixes = {"r_io", "r_pwr"};

fields = fieldnames(res);
for k = 1:numel(fields)
    name = fields{k};
    if ~ischar(name) || ~startsWith(name, 'r_')
        continue;
    end
    if endsWith(name, '_t_s')
        continue;
    end

    % Skip legacy residual families
    isLegacy = false;
    for j = 1:numel(legacyPrefixes)
        if startsWith(name, legacyPrefixes{j})
            isLegacy = true;
            break;
        end
    end
    if isLegacy
        continue;
    end

    if isKey(handled, name)
        continue;
    end

    x = res.(name);
    if isempty(x) || ~(isnumeric(x) || islogical(x))
        continue;
    end
    if ~isvector(x)
        continue;
    end
    x = x(:);

    t = [];
    tField = [name '_t_s'];
    if isfield(res, tField)
        t = res.(tField);
    elseif nargin >= 2 && isfield(feat, 'win_center_s') && numel(feat.win_center_s) == numel(x)
        t = feat.win_center_s;
    end
    if isempty(t)
        continue;
    end
    t = t(:);
    if numel(t) ~= numel(x)
        continue;
    end

    [t, x] = applyIgnore(t, x);
    if isempty(t)
        continue;
    end

    figure;
    plot(t, double(x)); grid on;
    xlabel('t [s]');
    ylabel(name, 'Interpreter', 'none');
    title(mkTitle(name), 'Interpreter', 'none');

    markHandled(name);
    if isfield(res, tField)
        markHandled(tField);
    end
end

% -----------------------
% Continuous-ish alarm state view (persistent until recovery)
% -----------------------
% This is intentionally separate from the raw residual plots.
% It makes it easier to see fault duration for sparse residuals (trav/dir)
% and for windowed residuals with NaNs (tick).
try
    S = build_alarm_states(res, feat, cal, p);
    tS = S.t_s(:);
    m = isfield(S,'mask') && ~isempty(S.mask);
    if m
        mask = S.mask(:);
    else
        mask = (tS >= t_ignore);
    end
    tS = tS(mask);

    plot_state = @(name, y) local_plot_state(mkTitle(name), tS, y(mask));

    % Disconnected (each on its own figure)
    if isfield(S,'motor_disc'), plot_state('state: motor_disc', double(S.motor_disc)); end
    if isfield(S,'tick_disc'),  plot_state('state: tick_disc',  double(S.tick_disc));  end
    if isfield(S,'s1_disc'),    plot_state('state: s1_disc',    double(S.s1_disc));    end
    if isfield(S,'s2_disc'),    plot_state('state: s2_disc',    double(S.s2_disc));    end
    if isfield(S,'lamps_disc'), plot_state('state: lamps_disc', double(S.lamps_disc)); end

    % Persistent states (each on its own figure)
    if isfield(S,'tick_state')
        figure;
        hold on;
        stairs(tS, double(S.tick_state(mask)), 'LineWidth', 1.2);
        if isfield(S,'tick_hi_state')
            stairs(tS, double(S.tick_hi_state(mask)), 'LineWidth', 1.2);
        end
        if isfield(S,'tick_nan')
            stairs(tS, double(S.tick_nan(mask)), '--', 'LineWidth', 1.0);
        end
        grid on; ylim([-0.1 1.1]);
        xlabel('t [s]'); ylabel('state');
        title(mkTitle('state: tick (persistent until recovery)'));
        legend({'tick','tick_hi','tick_nan'}, 'Interpreter','none', 'Location','best');
    end

    if isfield(S,'trav_state'), plot_state('state: trav (persistent until recovery)', double(S.trav_state)); end
    if isfield(S,'trav_hi_state'), plot_state('state: trav_hi (persistent until recovery)', double(S.trav_hi_state)); end

    if isfield(S,'dir_state')
        figure;
        hold on;
        stairs(tS, double(S.dir_state(mask)), 'LineWidth', 1.2);
        if isfield(S,'dir_nan_event_latest')
            stairs(tS, double(S.dir_nan_event_latest(mask)), '--', 'LineWidth', 1.0);
        end
        grid on; ylim([-0.1 1.1]);
        xlabel('t [s]'); ylabel('state');
        title(mkTitle('state: dir (persistent until recovery)'));
        legend({'dir','dir_nan_event_latest'}, 'Interpreter','none', 'Location','best');
    end
catch
    % If the helper is not on path or fails, keep plotting raw residuals.
end

end

function local_plot_state(ttl, t, y)
figure;
stairs(t, y, 'LineWidth', 1.2);
grid on;
ylim([-0.1 1.1]);
xlabel('t [s]');
ylabel('state');
title(ttl, 'Interpreter','none');
end
