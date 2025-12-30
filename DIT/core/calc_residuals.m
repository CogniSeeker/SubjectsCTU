function [res, feat] = calc_residuals(TT, cal, params)
%CALC_RESIDUALS  Compute residuals using precomputed calibration (no fitting).
%
% Uses existing helper functions:
%   debounce_times_adaptive, conveyor_near_flip_mask, sensor_events_active_low,
%   pair_traversals_by_events, dir_residual_at_events_dirgated
%
% Inputs:
%   TT     timetable
%   cal    struct with fields: k,b,sigma_f,T12_LR,T12_RL,sigmaT_LR,sigmaT_RL,tau_min,tau_max
%   params same as conveyor_defaults()

params = conveyor_defaults(params);

rt = TT.Properties.RowTimes;              % datetime/duration column of row times
t  = seconds(rt - rt(1)); 
t  = t(:);


s1   = TT.v_i0(:);
s2   = TT.v_i1(:);
v_i2 = TT.v_i2(:);
v_i3 = TT.v_i3(:);
% v_i4 = TT.v_i4(:);

thr_s1   = params.thr_s1;
thr_s2   = params.thr_s2;
thr_tick = params.thr_tick;

% Direction sign with deadband
dir = zeros(size(v_i2));
dir(v_i2 >  params.dirEps) = +1;
dir(v_i2 < -params.dirEps) = -1;

% Motor magnitude proxy (keep your current choice)
mv_abs = abs(v_i2);

% Tick rising edges -> times
tick_hi = (v_i3 > thr_tick);
tick_rise_idx = find(diff([false; tick_hi]) == 1);
t_tick_rise_raw = t(tick_rise_idx);
t_tick_rise = debounce_times_adaptive(t_tick_rise_raw, params.tickMinGap);

% Sliding windows features
W = params.W; S = params.S;
t0 = t(1); t1 = t(end);
win_starts  = (t0 : S : (t1 - W)).';
win_centers = win_starts + W/2;

% Direction flips for blanking
dir_nz = dir; dir_nz(dir_nz==0) = NaN;
for k = 2:numel(dir_nz)
    if isnan(dir_nz(k)), dir_nz(k) = dir_nz(k-1); end
end
k0 = find(~isnan(dir_nz), 1, 'first');
if ~isempty(k0) && k0 > 1, dir_nz(1:k0-1) = dir_nz(k0); end

flip_idx = find(dir_nz(1:end-1).*dir_nz(2:end) == -1) + 1;
t_flip = t(flip_idx);
if ~isempty(t_flip)
    keep = [true; diff(t_flip) >= params.minFlipGap];
    t_flip = t_flip(keep);
end

nearFlip = conveyor_near_flip_mask(win_centers, t_flip, params.revBlank);

f_tick   = nan(size(win_centers));
mv_mean  = nan(size(win_centers));
dir_const = false(size(win_centers));

% "Disconnected" residuals at window centers (binary)
r_tick_disc  = nan(size(win_centers));
r_motor_disc = nan(size(win_centers));
r_lamps_disc = nan(size(win_centers));

for i = 1:numel(win_centers)
    a = win_starts(i); b = a + W;
    inWin = (t >= a) & (t < b);

    % Tick frequency estimate: count rising edges per window.
    nEdges = sum((t_tick_rise >= a) & (t_tick_rise < b));
    f_tick(i) = nEdges / W;

    mv_mean(i) = mean(mv_abs(inWin), 'omitnan');

    d = dir(inWin); d = d(d ~= 0);
    dir_const(i) = ~isempty(d) && all(d == d(1));

    % ---- Disconnected detection (near-0V and low variance) ----
    % Tick channel (v_i3)
    % IMPORTANT: tickUseUntil_s is only for tick-*feature* usage (edge counting).
    % Disconnection is a wiring/ADC condition and should be evaluated over
    % the whole recording whenever v_i3 samples exist.
    x3 = v_i3(inWin);
    if ~isempty(x3) && any(isfinite(x3))
        r_tick_disc(i) = double(mean(abs(x3), 'omitnan') < params.tickDiscLowV && std(x3, 0, 'omitnan') < params.discStdV);
    else
        r_tick_disc(i) = NaN;
    end

    % Motor proxy (v_i2)
    x2 = v_i2(inWin);
    if ~isempty(x2)
        r_motor_disc(i) = double(mean(abs(x2), 'omitnan') < params.motorDiscLowV && std(x2, 0, 'omitnan') < params.discStdV);
    end

    % Lamp channel (v_i5) if present
    if ismember(params.lampVarName, TT.Properties.VariableNames)
        x5 = TT.(params.lampVarName)(inWin);
        if ~isempty(x5)
            r_lamps_disc(i) = double(mean(abs(x5), 'omitnan') < params.lampLowV && std(x5, 0, 'omitnan') < params.discStdV);
        end
    else
        r_lamps_disc(i) = NaN;
    end
end

motor_on = mv_mean > params.mvEps;
validWin = motor_on & dir_const & isfinite(f_tick) & isfinite(mv_mean) & ~nearFlip;

feat = struct();
feat.win_center_s     = win_centers;
feat.f_tick           = f_tick;
feat.mv_abs_mean      = mv_mean;
feat.validWindowMask  = validWin;

% Residual r_tick using fixed cal
r_tick = nan(size(win_centers));
r_tick(validWin) = abs(f_tick(validWin) - (cal.k*mv_mean(validWin) + cal.b)) ./ max(cal.sigma_f, eps);

% Sensor events
tS1 = sensor_events_active_low(t, s1, thr_s1, params.minSensorGap);
tS2 = sensor_events_active_low(t, s2, thr_s2, params.minSensorGap);

% Travel pairs
[LR, RL] = pair_traversals_by_events(tS1, tS2, t, dir, params.T12_min, params.T12_max);

% Travel residuals using fixed cal
LR.r_trav = abs(LR.T_meas_s - cal.T12_LR) ./ max(cal.sigmaT_LR, eps);
RL.r_trav = abs(RL.T_meas_s - cal.T12_RL) ./ max(cal.sigmaT_RL, eps);

% Direction residual using fixed cal tau bounds
% S1 event is only scored when dir just before the event is -1
r_dir_S1 = dir_residual_at_events_dirgated(tS1, t, dir, t_flip, cal.tau_min, cal.tau_max, -1);
r_dir_S2 = dir_residual_at_events_dirgated(tS2, t, dir, t_flip, cal.tau_min, cal.tau_max, +1);
% -----------------------
% r_io: lamp-based + pair-mismatch
% -----------------------

% Lamp voltage channel (v_i5)
v_lamp = [];
if ismember(params.lampVarName, TT.Properties.VariableNames)
    v_lamp = TT.(params.lampVarName)(:);
end

% Lamp-based events
[t_io_L1, r_io_L1, t_io_L2, r_io_L2] = deal([],[],[],[]);
if ~isempty(v_lamp)
    [t_io_L1, r_io_L1, t_io_L2, r_io_L2] = detect_rio_lamp_events(t, v_lamp, cal, params);
end

% Pair mismatch / timeout-style events (sensor-based)
[t_io_pair, r_io_pair] = detect_rio_pair_mismatch(tS1, tS2, cal, params);

% -----------------------
% r_pwr (tick disappearance while motor seems on)
% -----------------------
r_pwr = double(detect_rpwr_from_tick(win_centers, mv_mean, f_tick, params));
% When tick isn't available/considered, r_pwr is unknown (NaN), not false.
r_pwr(~isfinite(f_tick)) = NaN;

% -----------------------
% Sensor disconnect residuals (binary time series at window centers)
% -----------------------
[r_s1_disc, r_s2_disc] = detect_sensor_disconnect( ...
    t, s1, s2, win_centers, W, ...
    motor_on, dir_const, nearFlip, ...
    tS1, tS2, cal, params);

% -----------------------
% Build output struct ONCE (do not overwrite after setting fields)
% -----------------------
res = struct();

res.r_tick_t_s = win_centers;
res.r_tick     = r_tick;

res.LR = LR;
res.RL = RL;

res.r_dir_S1_t_s = tS1;
res.r_dir_S1     = r_dir_S1;
res.r_dir_S2_t_s = tS2;
res.r_dir_S2     = r_dir_S2;

% IO residuals
res.r_io_L1_t_s   = t_io_L1;
res.r_io_L1       = r_io_L1;

res.r_io_L2_t_s   = t_io_L2;
res.r_io_L2       = r_io_L2;

res.r_io_pair_t_s = t_io_pair;
res.r_io_pair     = r_io_pair;

% Power residual
res.r_pwr_t_s     = win_centers;
res.r_pwr         = r_pwr;

% lamps
res.r_s1_disc_t_s = win_centers;
res.r_s1_disc     = r_s1_disc;

res.r_s2_disc_t_s = win_centers;
res.r_s2_disc     = r_s2_disc;

% New: disconnected residuals
res.r_tick_disc_t_s  = win_centers;
res.r_tick_disc      = r_tick_disc;

res.r_motor_disc_t_s = win_centers;
res.r_motor_disc     = r_motor_disc;

res.r_lamps_disc_t_s = win_centers;
res.r_lamps_disc     = r_lamps_disc;

end

function [r_s1_disc, r_s2_disc] = detect_sensor_disconnect( ...
    t, s1, s2, win_centers, W, motor_on, dir_const, nearFlip, tS1, tS2, cal, params)
% Detect disconnected/stuck sensors:
%   1) Missing events for too long while motor is on (uses calibrated travel time)
%   2) Stuck-low signal (active-low sensor permanently triggered) with very low std in the window

nW = numel(win_centers);
r_s1_disc = false(nW,1);
r_s2_disc = false(nW,1);

% missing-event horizon derived from calibration (robust)
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
missingMax_s = 1.5 * max(T12) + params.sensorMissingMargin_s;

lowV  = params.sensorStuckLowV;
stdV  = params.sensorStuckStdV;

% pre-sort event times
tS1 = sort(tS1(:));
tS2 = sort(tS2(:));

last1 = -Inf; k1 = 1;
last2 = -Inf; k2 = 1;

for i = 1:nW
    t0 = win_centers(i);
    a  = t0 - W/2;
    b  = t0 + W/2;

    active = motor_on(i) && dir_const(i) && ~nearFlip(i);

    % update last event times up to t0
    while k1 <= numel(tS1) && tS1(k1) <= t0
        last1 = tS1(k1); k1 = k1 + 1;
    end
    while k2 <= numel(tS2) && tS2(k2) <= t0
        last2 = tS2(k2); k2 = k2 + 1;
    end

    miss1 = active && isfinite(last1) && ((t0 - last1) > missingMax_s);
    miss2 = active && isfinite(last2) && ((t0 - last2) > missingMax_s);

    % stuck check (use samples inside the window)
    inWin = (t >= a) & (t < b);
    s1w = s1(inWin);
    s2w = s2(inWin);

    med1 = median(s1w, 'omitnan'); sd1 = std(s1w, 0, 'omitnan');
    med2 = median(s2w, 'omitnan'); sd2 = std(s2w, 0, 'omitnan');

    % NOTE: Do NOT treat “stuck high” as disconnected. These are active-low sensors:
    % idle-high is normal between traversals, especially in short windows.
    % High-level disconnects are instead detected by the missing-event rule above.
    stuck1 = active && isfinite(med1) && isfinite(sd1) && (sd1 < stdV) && (med1 < lowV);
    stuck2 = active && isfinite(med2) && isfinite(sd2) && (sd2 < stdV) && (med2 < lowV);

    r_s1_disc(i) = miss1 || stuck1;
    r_s2_disc(i) = miss2 || stuck2;
end

% output as double 0/1 if you prefer (but logical is fine)
r_s1_disc = double(r_s1_disc);
r_s2_disc = double(r_s2_disc);
end
