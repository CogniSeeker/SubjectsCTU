function tE = sensor_events_active_low(t, x, thr, minGap)
%SENSOR_EVENTS_ACTIVE_LOW Events are falling-into-low (active-low dips).

active = (x < thr);
iStart = find(diff([false; active]) == 1); % enter low
tE = t(iStart);

% Debounce
if ~isempty(tE)
    keep = [true; diff(tE) >= minGap];
    tE = tE(keep);
end
end
