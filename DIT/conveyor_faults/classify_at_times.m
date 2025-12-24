function out = classify_at_times(ev, p)
%CLASSIFY_AT_TIMES Fuse residual fires in time and classify fault at each alarm time.

p = conveyor_alarm_defaults(p);

% Candidate times = all firing instants (union)
t = unique([ ...
    ev.tick.t_s(ev.tick.fire); ...
    ev.trav.t_s(ev.trav.fire); ...
    ev.dir.t_s(ev.dir.fire);  ...
    ev.io_L1.t_s(ev.io_L1.fire); ...
    ev.io_L2.t_s(ev.io_L2.fire); ...
    ev.io_pair.t_s(ev.io_pair.fire); ...
    ev.pwr.t_s(ev.pwr.fire); ...          
    ev.s1_disc.t_s(ev.s1_disc.fire); ...
    ev.s2_disc.t_s(ev.s2_disc.fire) ...
]);

t = t(:);  % ensure column

if isempty(t)
    out = table([], [], [], [], string.empty(0,1), ...
        'VariableNames', {'t_s','tick','trav','dir','class'});
    return;
end

% Helper: active if any fire in (t0-hold_s, t0]
isActive = @(t0, te, fe) any(fe & (te > (t0 - p.hold_s)) & (te <= t0));

tickA = false(size(t));
travA = false(size(t));
dirA  = false(size(t));
ioL1A = false(size(t));
ioL2A = false(size(t));
ioPairA = false(size(t));
pwrA = false(size(t));
s1A = false(size(t));
s2A = false(size(t));

for i = 1:numel(t)
    t0 = t(i);
    tickA(i)   = isActive(t0, ev.tick.t_s, ev.tick.fire);
    travA(i)   = isActive(t0, ev.trav.t_s, ev.trav.fire);
    dirA(i)    = isActive(t0, ev.dir.t_s,  ev.dir.fire);

    ioL1A(i)   = isActive(t0, ev.io_L1.t_s,   ev.io_L1.fire);
    ioL2A(i)   = isActive(t0, ev.io_L2.t_s,   ev.io_L2.fire);
    ioPairA(i) = isActive(t0, ev.io_pair.t_s, ev.io_pair.fire);

    pwrA(i)    = isActive(t0, ev.pwr.t_s, ev.pwr.fire);

    s1A(i) = isActive(t0, ev.s1_disc.t_s, ev.s1_disc.fire);
    s2A(i) = isActive(t0, ev.s2_disc.t_s, ev.s2_disc.fire);
end

lampA = ioL1A | ioL2A;

cls = repmat("NONE", numel(t), 1);

% ---- Gate: power overrides everything
cls(pwrA) = "GLOBAL_POWER";
np = ~pwrA;

% ---- New: explicit sensor disconnects (high priority)
cls(np & s1A & s2A)   = "SENSOR_BOTH_DISCONNECTED";
cls(np & s1A & ~s2A)  = "SENSOR_S1_DISCONNECTED";
cls(np & ~s1A & s2A)  = "SENSOR_S2_DISCONNECTED";

% ---- Only classify remaining times that are still NONE
free = np & (cls == "NONE");

% H-bridge stuck
cls(free & dirA & ~tickA & ~travA & ~ioPairA & ~lampA) = "HBRIDGE_STUCK";

% Lamp open
cls(free & lampA) = "LAMP_OPEN";

% Sensor misaligned
cls(free & ioPairA & travA) = "SENSOR_MISALIGNED";

% IO fault (pairing only)
cls(free & ioPairA & ~dirA & ~tickA & ~travA & ~lampA) = "IO_FAULT";

% Mechanical anomaly (jam/slip family without r_I separation)
cls(free & ~dirA & (tickA | travA) & ~ioPairA & ~lampA) = "MECH_ANOMALY";

% Mixed fallback
cls(free & (dirA | tickA | travA | ioPairA | lampA)) = "MIXED";


% ---- Locking / refractory between different classes (priority-based) ----
prio = containers.Map( ...
    ["GLOBAL_POWER", ...
     "SENSOR_BOTH_DISCONNECTED","SENSOR_S1_DISCONNECTED","SENSOR_S2_DISCONNECTED", ...
     "LAMP_OPEN","SENSOR_MISALIGNED","IO_FAULT", ...
     "HBRIDGE_STUCK","MECH_ANOMALY","MULTI_ANOMALY","MIXED","MIXED_WITH_IO","NONE"], ...
    [100, ...
      95,                     95,                     95, ...
      90,        80,               70, ...
      60,          50,            40,           30,    30,          0] );

getPrio = @(k) (prio(k) * isKey(prio,k) + 0 * ~isKey(prio,k));  % default 0 if missing

lastClass = "NONE";
lastTime  = -inf;

for i = 1:numel(t)
    c = cls(i);

    if c == "NONE"
        continue;
    end

    if lastClass == "NONE"
        lastClass = c;
        lastTime  = t(i);
        continue;
    end

    dt = t(i) - lastTime;

    % allow switch only if outside refractory OR higher priority
    if dt < p.refractory_s && getPrio(c) <= getPrio(lastClass)
        cls(i) = lastClass;  % suppress/snap to previous fault
    else
        lastClass = c;
        lastTime  = t(i);
    end
end



out = table(t, tickA, travA, dirA, ioPairA, ioL1A, ioL2A, pwrA, s1A, s2A, cls, ...
 'VariableNames', {'t_s','tick','trav','dir','io_pair','io_L1','io_L2','pwr','s1_disc','s2_disc','class'});

end
