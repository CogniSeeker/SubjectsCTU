function thr = pick_threshold(x, thrMode)
%PICK_THRESHOLD Robust threshold (midpoint of 5% and 95%) or numeric override.

x = x(:);
if isnumeric(thrMode)
    thr = thrMode;
    return;
end
lo = prctile(x, 5);
hi = prctile(x, 95);
thr = (lo + hi)/2;
end
