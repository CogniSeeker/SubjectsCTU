

function [cal, feat] = calibrate(TT, params)
%CALIBRATE  Calibration from timetable.
%
% This function estimates the calibration parameters needed by
% CALC_RESIDUALS:
%   cal.k, cal.b, cal.sigma_f
%   cal.T12_LR, cal.T12_RL, cal.sigmaT_LR, cal.sigmaT_RL
%   cal.tau_min, cal.tau_max
%   cal.lamp_mu, cal.lamp_sigma (optional, if v_i5 exists)
%
% It outputs the calibration struct CAL and the windowed feature struct FEAT.

params = conveyor_defaults(params);

% Tick usage cutoff (seconds from start). If the tick channel disappears
% mid-recording, set this to the last usable time.
tickUseUntil_s = params.tickUseUntil_s;
if isempty(tickUseUntil_s) || ~isscalar(tickUseUntil_s) || ~isfinite(tickUseUntil_s)
    tickUseUntil_s = Inf;
end

% -----------------------
% Extract time and channels
% -----------------------
rt = TT.Properties.RowTimes;              % datetime/duration column of row times
t  = seconds(rt - rt(1)); 
t  = t(:);

s1   = TT.v_i0(:);   % sensor S1 (left)  (confirmed mapping)
s2   = TT.v_i1(:);   % sensor S2 (right)
v_i2 = TT.v_i2(:);   % direction (diff)
v_i3 = TT.v_i3(:);   % tick
v_i4 = TT.v_i4(:);   % motor terminal (abs voltage & direction)

% -----------------------
% Thresholds
% -----------------------
thr_s1 = params.thr_s1;
thr_s2 = params.thr_s2;
thr_tick = params.thr_tick;

% -----------------------
% Direction sign with deadband
% -----------------------
dir = zeros(size(v_i2));
dir(v_i2 >  params.dirEps) = +1;
dir(v_i2 < -params.dirEps) = -1;
fprintf("dir counts: -1=%d, 0=%d, +1=%d\n", nnz(dir==-1), nnz(dir==0), nnz(dir==+1));
fprintf("med v_i4: dir-1=%.3f, dir+1=%.3f\n", ...
    median(v_i4(dir==-1), 'omitnan'), median(v_i4(dir==+1), 'omitnan'));

% Motor magnitude
mv_abs = abs(v_i2); % !!!
% mv_abs = abs(v_i4);

% % Motor magnitude estimate:
% % v_i4 can be clipped (e.g., one polarity clamps to ~0 V on single-supply ADC).
% % If that happens, use |v_i2| as motor magnitude proxy.
% mv_abs = abs(v_i4);
% 
% idxNeg = (dir == -1);
% idxPos = (dir == +1);
% 
% pNegZero = mean(abs(v_i4(idxNeg)) < 2.0, 'omitnan');
% pPosZero = mean(abs(v_i4(idxPos)) < 2.0, 'omitnan');
% 
% fprintf("pNegZero=%.3f, pPosZero=%.3f\n", pNegZero, pPosZero);
% 
% if (pNegZero > 0.4 && mean(abs(v_i4(dir == +1)), 'omitnan') > 1.0) || ...
%    (pPosZero > 0.4 && mean(abs(v_i4(dir == -1)), 'omitnan') > 1.0)
%     mv_abs = abs(v_i2);
%     fprintf("Switched from i_v4 to i_v2 for motor average\n");
% end


% -----------------------
% Tick rising edges -> times (with adaptive debounce)
% -----------------------
tick_hi = (v_i3 > thr_tick);
tick_rise_idx = find(diff([false; tick_hi]) == 1);
t_tick_rise_raw = t(tick_rise_idx);
t_tick_rise = debounce_times_adaptive(t_tick_rise_raw, params.tickMinGap);
% Use tick only up to cutoff
t_tick_rise = t_tick_rise(t_tick_rise <= tickUseUntil_s);

% -----------------------
% Sliding windows -> f_tick and mean |M_V|
% -----------------------
W = params.W; S = params.S;
t0 = t(1); t1 = t(end);
win_starts  = (t0 : S : (t1 - W)).';
win_centers = win_starts + W/2;

% Direction flips (for blanking + tau)
dir_nz = dir;
dir_nz(dir_nz==0) = NaN;

% forward-fill NaNs to hold last direction through deadband
for k = 2:numel(dir_nz)
    if isnan(dir_nz(k))
        dir_nz(k) = dir_nz(k-1);
    end
end
% backward-fill if signal starts with NaNs
k0 = find(~isnan(dir_nz), 1, 'first');
if ~isempty(k0) && k0 > 1
    dir_nz(1:k0-1) = dir_nz(k0);
end

flip_idx = find(dir_nz(1:end-1).*dir_nz(2:end) == -1) + 1;
t_flip = t(flip_idx);

% debounce flips (collapse multiple detections around same reversal)
if ~isempty(t_flip)
    keep = [true; diff(t_flip) > params.minFlipGap];
    t_flip = t_flip(keep);
end


% Debounce direction flips (remove sign-chatter around reversal)
if ~isempty(t_flip)
    keep = [true; diff(t_flip) >= params.minFlipGap];
    t_flip = t_flip(keep);
end

fprintf("number of flips: %d\n", numel(t_flip));
if numel(t_flip) > 1
    fprintf("flip diff: min=%.3f med=%.3f max=%.3f\n", ...
        min(diff(t_flip)), median(diff(t_flip)), max(diff(t_flip)));
end


nearFlip = conveyor_near_flip_mask(win_centers, t_flip, params.revBlank);

f_tick   = nan(size(win_centers));
mv_mean  = nan(size(win_centers));
dir_const = false(size(win_centers));

for i = 1:numel(win_centers)
    a = win_starts(i);
    b = a + W;

    inWin = (t >= a) & (t < b);

    % Stable tick frequency estimate: counts per window
    % Only compute f_tick when the whole window is within the tick-valid range.
    if b <= tickUseUntil_s
        nEdges = sum((t_tick_rise >= a) & (t_tick_rise < b));
        f_tick(i) = nEdges / W;
    else
        f_tick(i) = NaN;
    end

    mv_mean(i) = mean(mv_abs(inWin), 'omitnan');

    d = dir(inWin);
    d = d(d ~= 0);
    dir_const(i) = ~isempty(d) && all(d == d(1));
end

motor_on = mv_mean > params.mvEps;
validWin = motor_on & dir_const & isfinite(f_tick) & isfinite(mv_mean) & ~nearFlip;

feat = struct();
feat.win_center_s     = win_centers;
feat.f_tick           = f_tick;
feat.mv_abs_mean      = mv_mean;
feat.validWindowMask  = validWin;

% -----------------------
% Calibrate k,b: f_tick ≈ k*|M_V| + b
% -----------------------
x = mv_mean(validWin);
y = f_tick(validWin);

if numel(x) < 10
    error('Not enough valid windows to fit k,b (need more baseline-like data).');
end

if exist('robustfit','file') == 2
    beta = robustfit(x, y);   % y ≈ beta(1) + beta(2)*x
    b_hat = beta(1);
    k_hat = beta(2);
    fprintf('Robust fit used for fitting k and b\n');
else
    p = polyfit(x, y, 1);     % y ≈ p(1)*x + p(2)
    k_hat = p(1);
    b_hat = p(2);
    fprintf('Polyfit fit used for fitting k and b\n');
end

e_f = y - (k_hat*x + b_hat);
sigma_f = robust_sigma(e_f);

% -----------------------
% Sensor event times (forced active-low + debounce)
% -----------------------
tS1 = sensor_events_active_low(t, s1, thr_s1, params.minSensorGap);
tS2 = sensor_events_active_low(t, s2, thr_s2, params.minSensorGap);

fprintf("S1 events: %d, S2 events: %d\n", numel(tS1), numel(tS2));
if numel(tS1) > 1
    fprintf("S1 diff: min=%.3f med=%.3f max=%.3f\n", min(diff(tS1)), median(diff(tS1)), max(diff(tS1)));
end
if numel(tS2) > 1
    fprintf("S2 diff: min=%.3f med=%.3f max=%.3f\n", min(diff(tS2)), median(diff(tS2)), max(diff(tS2)));
end


% -----------------------
% Travel times: segment by direction intervals
% -----------------------
[LR, RL] = pair_traversals_by_events(tS1, tS2, t, dir, params.T12_min, params.T12_max);

% Expected travel times (direction-wise medians)
T12_LR = median(LR.T_meas_s, 'omitnan');
T12_RL = median(RL.T_meas_s, 'omitnan');

% Estimate traversal-time variability.
% With very few pairs (3–5), MAD can underestimate spread (and can hit 0 if
% at least half of samples are identical/quantized). Use a conservative
% small-sample estimator: max(MAD, IQR/1.349, sample std).
eLR = LR.T_meas_s - T12_LR;
eRL = RL.T_meas_s - T12_RL;

[sigmaT_LR_mad, sigmaT_LR_iqr, sigmaT_LR_std] = local_sigma_components(eLR);
[sigmaT_RL_mad, sigmaT_RL_iqr, sigmaT_RL_std] = local_sigma_components(eRL);

sigmaT_LR = max([sigmaT_LR_mad, sigmaT_LR_iqr, sigmaT_LR_std]);
sigmaT_RL = max([sigmaT_RL_mad, sigmaT_RL_iqr, sigmaT_RL_std]);

% Crop it from the bottom (avoid tiny sigma blow-up downstream)
sigmaT_LR = max(sigmaT_LR, 0.3);
sigmaT_RL = max(sigmaT_RL, 0.3);

% Diagnostic: print components when we end up at the floor.
if ~isfinite(sigmaT_LR) || sigmaT_LR <= 0.3
    fprintf('sigmaT_LR floor: MAD=%.6f IQR=%.6f STD=%.6f -> %.3f; T12_LR=%.6f; LR.T_meas_s=%s\n', ...
        sigmaT_LR_mad, sigmaT_LR_iqr, sigmaT_LR_std, sigmaT_LR, T12_LR, mat2str(LR.T_meas_s(:).', 6));
end
if ~isfinite(sigmaT_RL) || sigmaT_RL <= 0.3
    fprintf('sigmaT_RL floor: MAD=%.6f IQR=%.6f STD=%.6f -> %.3f; T12_RL=%.6f; RL.T_meas_s=%s\n', ...
        sigmaT_RL_mad, sigmaT_RL_iqr, sigmaT_RL_std, sigmaT_RL, T12_RL, mat2str(RL.T_meas_s(:).', 6));
end

fprintf("pairs: LR=%d, RL=%d\n", numel(LR.T_meas_s), numel(RL.T_meas_s));

% -----------------------
% tau_min/tau_max from observed delays: sensor event -> next direction flip
% -----------------------
[tau_min, tau_max] = estimate_tau_bounds_dirgated(tS1, tS2, t, dir, t_flip, params.tauSearchMax);

% -----------------------
% Lamp baseline stats (optional v_i5)
% -----------------------
lamp_mu = NaN;
lamp_sigma = NaN;

if ismember(params.lampVarName, TT.Properties.VariableNames)
    v_lamp = TT.(params.lampVarName)(:);
    ok = isfinite(v_lamp) & (v_lamp > params.lampLowV); % exclude near-zero (L1 open)
    if nnz(ok) >= 50
        lamp_mu = median(v_lamp(ok), 'omitnan');
        lamp_sigma = robust_sigma(v_lamp(ok) - lamp_mu);
        lamp_sigma = max(lamp_sigma, 0.002); % avoid tiny sigma blow-up
    end
end

% -----------------------
% Outputs
% -----------------------
cal = struct();
cal.k         = k_hat;
cal.b         = b_hat;
cal.sigma_f   = sigma_f;
cal.T12_LR    = T12_LR;
cal.T12_RL    = T12_RL;
cal.sigmaT_LR = sigmaT_LR;
cal.sigmaT_RL = sigmaT_RL;
cal.tau_min   = tau_min;
cal.tau_max   = tau_max;
cal.lamp_mu   = lamp_mu;
cal.lamp_sigma = lamp_sigma;

end

function [s_mad, s_iqr, s_std] = local_sigma_components(e)
e = e(:);
e = e(isfinite(e));
if isempty(e)
    s_mad = NaN; s_iqr = NaN; s_std = NaN;
    return;
end

s_mad = robust_sigma(e);

if numel(e) >= 2
    % Sample std (small-n friendly; outlier-sensitive but ok for n<=5)
    s_std = std(e, 0);

    % IQR-based sigma (robust-ish): sigma ~= IQR / 1.349 for normal data
    es = sort(e);
    q1 = local_quantile_sorted(es, 0.25);
    q3 = local_quantile_sorted(es, 0.75);
    s_iqr = (q3 - q1) / 1.349;
else
    s_std = 0;
    s_iqr = 0;
end
end

function q = local_quantile_sorted(xSorted, p)
% Linear-interpolated quantile for a sorted vector (p in [0,1]).
n = numel(xSorted);
if n == 0
    q = NaN;
    return;
elseif n == 1
    q = xSorted(1);
    return;
end

p = min(max(p, 0), 1);
pos = (n - 1) * p + 1;
i = floor(pos);
f = pos - i;
if i >= n
    q = xSorted(n);
else
    q = (1 - f) * xSorted(i) + f * xSorted(i + 1);
end
end
