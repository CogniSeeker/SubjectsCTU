function out = classify_at_times(ev, p)
%CLASSIFY_AT_TIMES Fuse residual fires in time and classify fault at each alarm time.
%
% The classifier is rule-based over a small set of residual "active" flags.
% It uses a hold window (p.hold_s) to associate events and a refractory
% period (p.refractory_s) to avoid chattering between classes.

p = conveyor_alarm_defaults(p);

% Helper: safe get event (returns empty fields when missing)
getEv = @(name) get_event_or_empty(ev, name);

E.tick      = getEv('tick');
E.tick_hi   = getEv('tick_hi');
E.trav      = getEv('trav');
E.trav_hi   = getEv('trav_hi');
E.dir       = getEv('dir');

E.s1_disc   = getEv('s1_disc');
E.s2_disc   = getEv('s2_disc');
E.lamps_disc= getEv('lamps_disc');
E.motor_disc= getEv('motor_disc');
E.tick_disc = getEv('tick_disc');

% Candidate times = union of all firing instants
t = unique([ ...
    E.tick.t_s(E.tick.fire); ...
    E.trav.t_s(E.trav.fire); ...
    E.dir.t_s(E.dir.fire); ...
    E.s1_disc.t_s(E.s1_disc.fire); ...
    E.s2_disc.t_s(E.s2_disc.fire); ...
    E.lamps_disc.t_s(E.lamps_disc.fire); ...
    E.motor_disc.t_s(E.motor_disc.fire); ...
    E.tick_disc.t_s(E.tick_disc.fire); ...
    E.tick_hi.t_s(E.tick_hi.fire); ...
    E.trav_hi.t_s(E.trav_hi.fire) ...
]);
t = t(:);

if isempty(t)
    out = table([], logical([]), logical([]), logical([]), logical([]), logical([]), logical([]), logical([]), logical([]), logical([]), string.empty(0,1), ...
        'VariableNames', {'t_s','tick','tick_hi','trav','trav_hi','dir','lamps_disc','s1_disc','s2_disc','motor_disc','tick_disc','class'});
    return;
end

% Helper: active if any fire in (t0-hold_s, t0]
isActive = @(t0, te, fe) any(fe & (te > (t0 - p.hold_s)) & (te <= t0));

tickA     = false(size(t));
tickHiA   = false(size(t));
travA     = false(size(t));
travHiA   = false(size(t));
dirA      = false(size(t));

lampsDiscA = false(size(t));
motorDiscA = false(size(t));
tickDiscA  = false(size(t));
s1A        = false(size(t));
s2A        = false(size(t));

for i = 1:numel(t)
    t0 = t(i);
    tickA(i)   = isActive(t0, E.tick.t_s,    E.tick.fire);
    tickHiA(i) = isActive(t0, E.tick_hi.t_s, E.tick_hi.fire);

    travA(i)   = isActive(t0, E.trav.t_s,    E.trav.fire);
    travHiA(i) = isActive(t0, E.trav_hi.t_s, E.trav_hi.fire);

    dirA(i)    = isActive(t0, E.dir.t_s,     E.dir.fire);

    lampsDiscA(i) = isActive(t0, E.lamps_disc.t_s, E.lamps_disc.fire);
    motorDiscA(i) = isActive(t0, E.motor_disc.t_s, E.motor_disc.fire);
    tickDiscA(i)  = isActive(t0, E.tick_disc.t_s,  E.tick_disc.fire);

    s1A(i) = isActive(t0, E.s1_disc.t_s, E.s1_disc.fire);
    s2A(i) = isActive(t0, E.s2_disc.t_s, E.s2_disc.fire);
end

% -----------------------
% Rule-based classification
% -----------------------
cls = repmat("NONE", numel(t), 1);

% Convenience: all flags in a fixed order (for "no other residuals" gating)
F = [tickA, tickHiA, travA, travHiA, dirA, lampsDiscA, s1A, s2A, motorDiscA, tickDiscA];
names = ["tick","tick_hi","trav","trav_hi","dir","lamps_disc","s1_disc","s2_disc","motor_disc","tick_disc"]; %#ok<NASGU>

onlyAllowed = @(allowedIdx) ~any(F(:, setdiff(1:size(F,2), allowedIdx)), 2);

% 5) Tick disc: r_tick_disc only
idx = tickDiscA & onlyAllowed([10]);
cls(idx) = "TICK_DISCONNECTED";

free = (cls == "NONE");

% 1) Motor disconnected: r_motor_disc, r_dir, r_tick, (r_trav)
idx = free & motorDiscA & dirA & tickA & onlyAllowed([2 4 5 9]);
cls(idx) = "MOTOR_DISCONNECTED";

free = (cls == "NONE");

% 2) S1 disc: r_s1_disc, r_trav, (r_dir)
idx = free & s1A & travA & onlyAllowed([3 5 7]);
cls(idx) = "S1_DISCONNECTED";

free = (cls == "NONE");

% 3) S2 disc: r_s2_disc, r_trav, (r_dir)
idx = free & s2A & travA & onlyAllowed([3 5 8]);
cls(idx) = "S2_DISCONNECTED";

free = (cls == "NONE");

% 4) Lamps disc: r_lamps_disc, (r_trav, r_s1_disc, r_s2_disc, r_dir)
idx = free & lampsDiscA & onlyAllowed([3 5 6 7 8]);
cls(idx) = "LAMPS_DISCONNECTED";

free = (cls == "NONE");

% 9) Motor shifted: r_tick very high, r_dir, r_trav
idx = free & tickHiA & dirA & travA & onlyAllowed([1 2 3 4 5]);
cls(idx) = "MOTOR_SHIFTED";

free = (cls == "NONE");

% 6) Belt abnormal speed: r_tick (not very high), (r_trav, r_dir)
idx = free & tickA & ~tickHiA & onlyAllowed([1 3 5]);
cls(idx) = "BELT_ABNORMAL_SPEED";

free = (cls == "NONE");

% 7) Belt stuck in one dir: r_dir and big r_trav
idx = free & dirA & travHiA & onlyAllowed([3 4 5]);
cls(idx) = "BELT_STUCK_ONE_DIR";

free = (cls == "NONE");

% 8) Foreign objects triggering dir switch: r_dir, r_trav
idx = free & dirA & travA & onlyAllowed([3 5]);
cls(idx) = "FOREIGN_OBJECTS_DIR_SWITCH";

free = (cls == "NONE");

% Fallback when something fired but no strict rule matched
anyFired = any(F, 2);
cls(free & anyFired) = "MIXED";

% -----------------------
% Refractory / locking between different classes (priority-based)
% -----------------------
prio = containers.Map( ...
    ["TICK_DISCONNECTED", "MOTOR_DISCONNECTED", "S1_DISCONNECTED", "S2_DISCONNECTED", "LAMPS_DISCONNECTED", ...
     "MOTOR_SHIFTED", "BELT_STUCK_ONE_DIR", "BELT_ABNORMAL_SPEED", "FOREIGN_OBJECTS_DIR_SWITCH", "MIXED", "NONE"], ...
    [100,                95,                  92,               92,               90, ...
     80,            70,                  60,                 50,                      10,     0] );

getPrio = @(k) (prio(k) * isKey(prio,k) + 0 * ~isKey(prio,k));

lastClass = "NONE";
lastTime  = -inf;
for i = 1:numel(t)
    c = cls(i);
    if c == "NONE", continue; end
    if lastClass == "NONE"
        lastClass = c; lastTime = t(i); continue;
    end

    dt = t(i) - lastTime;
    if dt < p.refractory_s && getPrio(c) <= getPrio(lastClass)
        cls(i) = lastClass;
    else
        lastClass = c;
        lastTime  = t(i);
    end
end

out = table(t, tickA, tickHiA, travA, travHiA, dirA, lampsDiscA, s1A, s2A, motorDiscA, tickDiscA, cls, ...
    'VariableNames', {'t_s','tick','tick_hi','trav','trav_hi','dir','lamps_disc','s1_disc','s2_disc','motor_disc','tick_disc','class'});

end

function e = get_event_or_empty(ev, name)
% Return ev.(name) if present, else a default empty event.
e = struct('t_s',[], 'fire',false(0,1));
if isstruct(ev) && isfield(ev, name)
    tmp = ev.(name);
    if isstruct(tmp) && isfield(tmp,'t_s') && isfield(tmp,'fire')
        e.t_s = tmp.t_s(:);
        e.fire = logical(tmp.fire(:));
    end
end
end
