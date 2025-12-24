function tD = debounce_times_adaptive(tRaw, fallbackMinGap)
%DEBOUNCE_TIMES_ADAPTIVE Adaptive debounce based on median inter-edge interval.

tRaw = tRaw(:);
if numel(tRaw) < 2
    tD = tRaw;
    return;
end

dt = diff(tRaw);
dt = dt(dt > 0 & isfinite(dt));
if isempty(dt)
    minGap = fallbackMinGap;
    fprintf("Fallback to Min Gap\n");
else
    med = median(dt);
    minGap = max(fallbackMinGap, 0.5 * med);
    fprintf("The calculated min gap: %d, the final chosen: %d\n", 0.5 * med, minGap);
end

keep = [true; diff(tRaw) >= minGap];
tD = tRaw(keep);
end
