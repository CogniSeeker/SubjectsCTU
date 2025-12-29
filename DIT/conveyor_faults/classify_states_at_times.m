function alarms = classify_states_at_times(S, p)
%CLASSIFY_STATES_AT_TIMES Classify faults based on persistent alarm states.
%
% Input S is from build_alarm_states(res, feat, cal, p).
% Output is a table over window centers (t_s), filtered to t >= ignore horizon.

p = conveyor_alarm_defaults(p);

if ~isstruct(S) || ~isfield(S,'t_s')
    error('classify_states_at_times:BadInput', 'Expected S from build_alarm_states with field t_s.');
end

t = S.t_s(:);
if isfield(S,'mask') && ~isempty(S.mask)
    mask = logical(S.mask(:));
else
    mask = true(size(t));
end

% Pull states (default false)
% Disconnected
motor_disc = toL(S, 'motor_disc', numel(t));
tick_disc  = toL(S, 'tick_disc',  numel(t));
s1_disc    = toL(S, 's1_disc',    numel(t));
s2_disc    = toL(S, 's2_disc',    numel(t));
lamps_disc = toL(S, 'lamps_disc', numel(t));

% Persistent residual states
% Expose with the same column names as the legacy classifier.
tick    = toL(S, 'tick_state',    numel(t));
tick_hi = toL(S, 'tick_hi_state', numel(t));
trav    = toL(S, 'trav_state',    numel(t));
trav_hi = toL(S, 'trav_hi_state', numel(t));
dir     = toL(S, 'dir_state',     numel(t));

% NaN indicator (do not discard)
tick_nan = toL(S, 'tick_nan', numel(t));

% Optional experiment: ignore tick_disc (e.g., sensor unplugged)
if isfield(p,'ignore_tick_disc') && p.ignore_tick_disc
    tick_disc(:) = false;
end

% Apply ignore mask
idx = find(mask);
t = t(idx);

motor_disc = motor_disc(idx);
tick_disc  = tick_disc(idx);
s1_disc    = s1_disc(idx);
s2_disc    = s2_disc(idx);
lamps_disc = lamps_disc(idx);

tick    = tick(idx);
tick_hi = tick_hi(idx);
trav    = trav(idx);
trav_hi = trav_hi(idx);
dir     = dir(idx);
tick_nan = tick_nan(idx);

% -----------------------
% Rule-based classification on states
% -----------------------
cls = repmat("NONE", numel(t), 1);

% Treat tick_nan as "tick not evaluable" signal; allow it to support motor disconnect.
tick_bad = tick | tick_nan;

F = [tick, tick_hi, trav, trav_hi, dir, lamps_disc, s1_disc, s2_disc, motor_disc, tick_disc];
onlyAllowed = @(allowedIdx) ~any(F(:, setdiff(1:size(F,2), allowedIdx)), 2);

% 5) Tick disconnected (pure)
sel = tick_disc & onlyAllowed([10]);
cls(sel) = "TICK_DISCONNECTED";

free = (cls == "NONE");

% 1) Motor disconnected
% For state-based classification we do NOT require trav/dir/tick to be true,
% because during some faults those residuals may be unavailable.
% We still demand that other disconnect alarms are not active.
sel = free & motor_disc & ~s1_disc & ~s2_disc & ~lamps_disc & onlyAllowed([1 2 3 4 5 9 10]);
% Prefer when we also see tick_bad or any mechanical symptom
sel = sel & (tick_bad | trav | dir | tick_disc);
cls(sel) = "MOTOR_DISCONNECTED";

free = (cls == "NONE");

% 2) S1 disconnected
sel = free & s1_disc & onlyAllowed([3 5 7]);
cls(sel) = "S1_DISCONNECTED";

free = (cls == "NONE");

% 3) S2 disconnected
sel = free & s2_disc & onlyAllowed([3 5 8]);
cls(sel) = "S2_DISCONNECTED";

free = (cls == "NONE");

% 4) Lamps disconnected
sel = free & lamps_disc & onlyAllowed([3 5 6 7 8]);
cls(sel) = "LAMPS_DISCONNECTED";

free = (cls == "NONE");

% 9) Motor shifted
sel = free & tick_hi & dir & trav & onlyAllowed([1 2 3 4 5]);
cls(sel) = "MOTOR_SHIFTED";

free = (cls == "NONE");

% 6) Belt abnormal speed
sel = free & tick & ~tick_hi & onlyAllowed([1 3 5]);
cls(sel) = "BELT_ABNORMAL_SPEED";

free = (cls == "NONE");

% 7) Belt stuck in one dir
sel = free & dir & trav_hi & onlyAllowed([3 4 5]);
cls(sel) = "BELT_STUCK_ONE_DIR";

free = (cls == "NONE");

% 8) Foreign objects triggering dir switch
sel = free & dir & trav & onlyAllowed([3 5]);
cls(sel) = "FOREIGN_OBJECTS_DIR_SWITCH";

free = (cls == "NONE");

anyFired = any(F, 2) | tick_nan;
cls(free & anyFired) = "MIXED";

% -----------------------
% Refractory / locking (priority-based)
% -----------------------
prio = containers.Map( ...
    ["TICK_DISCONNECTED", "MOTOR_DISCONNECTED", "S1_DISCONNECTED", "S2_DISCONNECTED", "LAMPS_DISCONNECTED", ...
     "MOTOR_SHIFTED", "BELT_STUCK_ONE_DIR", "BELT_ABNORMAL_SPEED", "FOREIGN_OBJECTS_DIR_SWITCH", "MIXED", "NONE"], ...
    [100,                95,                  92,               92,               90, ...
     80,                 70,                  60,               50,               10,     0] );

lastClass = "NONE";
lastTime  = -inf;
for i = 1:numel(t)
    c = cls(i);
    if c == "NONE", continue; end
    if lastClass == "NONE"
        lastClass = c;
        lastTime  = t(i);
        continue;
    end

    dt = t(i) - lastTime;
    if dt < p.refractory_s && prio(c) <= prio(lastClass)
        cls(i) = lastClass;
    else
        lastClass = c;
        lastTime  = t(i);
    end
end

alarms = table(t, tick, tick_hi, trav, trav_hi, dir, lamps_disc, s1_disc, s2_disc, motor_disc, tick_disc, tick_nan, cls, ...
    'VariableNames', {'t_s','tick','tick_hi','trav','trav_hi','dir','lamps_disc','s1_disc','s2_disc','motor_disc','tick_disc','tick_nan','class'});

end

function x = toL(S, name, n)
if isfield(S, name)
    v = S.(name);
    if isempty(v)
        x = false(n,1);
    else
        x = logical(v(:));
        if numel(x) ~= n
            error('classify_states_at_times:BadSize', 'Field %s has wrong length (%d != %d).', name, numel(x), n);
        end
    end
else
    x = false(n,1);
end
end
