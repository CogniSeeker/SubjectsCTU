function tE = sensor_events_active_low(t, x, thr, minGap)
%SENSOR_EVENTS_ACTIVE_LOW Events are falling-into-low (active-low dips).
%
% An "enter low" event is emitted only if the signal stays below the
% threshold for at least conveyor_defaults().sensorLowMinDur_s seconds.

p0 = conveyor_defaults(struct());
minLowDur_s = p0.sensorLowMinDur_s;

% Estimate sampling period (used to make segment duration inclusive).
dt = median(diff(t), 'omitnan');
if isempty(dt) || ~isfinite(dt) || dt < 0
    dt = 0;
end

active = (x < thr);

% Find contiguous low segments
iStart = find(diff([false; active]) == 1); % first low sample index
iEndLast = find(diff([active; false]) == -1); % last low sample index

% Guard against malformed input
if isempty(iStart) || isempty(iEndLast)
    tE = [];
    return;
end

% Keep only segments that are "long enough".
% Use an inclusive duration so a 1-sample dip counts as ~dt, not 0.
segDur = (t(iEndLast) - t(iStart)) + dt;
okSeg = (segDur >= minLowDur_s);
tE = t(iStart(okSeg));

% Debounce (minimum time between accepted events)
if ~isempty(tE)
    keep = [true; diff(tE) >= minGap];
    tE = tE(keep);
end
end
