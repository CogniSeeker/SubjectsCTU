function ev = extract_residual_events(res, feat, cal, p)

p = conveyor_alarm_defaults(p);

% ignore horizon: max(5 s, 2 * max traversal time)
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
if isempty(T12)
    t_ignore = p.t_ignore_s;
else
    t_ignore = max(p.t_ignore_s, 2.0 * max(T12));
end

% ---- r_tick
t_tick = res.r_tick_t_s(:);
x_tick = res.r_tick(:);
ok = isfinite(t_tick) & isfinite(x_tick) & (t_tick >= t_ignore);
t_tick = t_tick(ok); x_tick = x_tick(ok);
tick_fire = x_tick > p.thr_r_tick;

% ---- r_trav
t_trav = []; x_trav = [];
if isfield(res,'LR')
    t_trav = [t_trav; res.LR.t_start_s(:)];
    x_trav = [x_trav; res.LR.r_trav(:)];
end
if isfield(res,'RL')
    t_trav = [t_trav; res.RL.t_start_s(:)];
    x_trav = [x_trav; res.RL.r_trav(:)];
end
ok = isfinite(t_trav) & isfinite(x_trav) & (t_trav >= t_ignore);
t_trav = t_trav(ok); x_trav = x_trav(ok);
trav_fire = x_trav > p.thr_r_trav;

% ---- r_dir
t_dir = [res.r_dir_S1_t_s(:); res.r_dir_S2_t_s(:)];
x_dir = [res.r_dir_S1(:);     res.r_dir_S2(:)];
ok = isfinite(t_dir) & isfinite(x_dir) & (t_dir >= t_ignore);
t_dir = t_dir(ok); x_dir = x_dir(ok);
dir_fire = x_dir > 0.5;

ev.tick.t_s = t_tick; ev.tick.fire = tick_fire;
ev.trav.t_s = t_trav; ev.trav.fire = trav_fire;
ev.dir.t_s  = t_dir;  ev.dir.fire  = dir_fire;

% ---- r_io (lamp L1/L2 + pair mismatch)
% Lamp L1
if isfield(res,'r_io_L1_t_s') && isfield(res,'r_io_L1')
    t1 = res.r_io_L1_t_s(:); x1 = res.r_io_L1(:);
    ok = isfinite(t1) & isfinite(x1) & (t1 >= t_ignore);
    ev.io_L1.t_s = t1(ok); ev.io_L1.fire = x1(ok) > 0.5;
else
    ev.io_L1.t_s = []; ev.io_L1.fire = false(0,1);
end

% Lamp L2
if isfield(res,'r_io_L2_t_s') && isfield(res,'r_io_L2')
    t2 = res.r_io_L2_t_s(:); x2 = res.r_io_L2(:);
    ok = isfinite(t2) & isfinite(x2) & (t2 >= t_ignore);
    ev.io_L2.t_s = t2(ok); ev.io_L2.fire = x2(ok) > 0.5;
else
    ev.io_L2.t_s = []; ev.io_L2.fire = false(0,1);
end

% Pair mismatch
if isfield(res,'r_io_pair_t_s') && isfield(res,'r_io_pair')
    tp = res.r_io_pair_t_s(:); xp = res.r_io_pair(:);
    ok = isfinite(tp) & isfinite(xp) & (tp >= t_ignore);
    ev.io_pair.t_s = tp(ok); ev.io_pair.fire = xp(ok) > 0.5;
else
    ev.io_pair.t_s = []; ev.io_pair.fire = false(0,1);
end

% ---- r_pwr (binary time series)
if isfield(res,'r_pwr_t_s') && isfield(res,'r_pwr')
    t_pwr = res.r_pwr_t_s(:);
    x_pwr = res.r_pwr(:);
    ok = isfinite(t_pwr) & isfinite(x_pwr) & (t_pwr >= t_ignore);
    ev.pwr.t_s = t_pwr(ok);
    ev.pwr.fire = x_pwr(ok) > 0.5;
else
    ev.pwr.t_s = []; ev.pwr.fire = false(0,1);
end

% ---- r_s1_disc (binary time series)
t_s1 = res.r_s1_disc_t_s(:);
x_s1 = res.r_s1_disc(:);
ok = isfinite(t_s1) & isfinite(x_s1) & (t_s1 >= t_ignore);
t_s1 = t_s1(ok); x_s1 = x_s1(ok);
s1_fire = x_s1 > 0.5;

% ---- r_s2_disc (binary time series)
t_s2 = res.r_s2_disc_t_s(:);
x_s2 = res.r_s2_disc(:);
ok = isfinite(t_s2) & isfinite(x_s2) & (t_s2 >= t_ignore);
t_s2 = t_s2(ok); x_s2 = x_s2(ok);
s2_fire = x_s2 > 0.5;

ev.s1_disc.t_s = t_s1; ev.s1_disc.fire = s1_fire;
ev.s2_disc.t_s = t_s2; ev.s2_disc.fire = s2_fire;


ev.meta.t_ignore_s = t_ignore; % optional for printing/debug
end
