function s = robust_sigma(e)
%ROBUST_SIGMA Robust sigma via scaled MAD.

e = e(:); % convert to column vector
e = e(isfinite(e));
if isempty(e)
    s = NaN;
    return;
end
m = median(e);
mad0 = median(abs(e - m));
s = 1.4826 * mad0;
end
