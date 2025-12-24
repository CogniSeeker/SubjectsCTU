function [t_io, r_io] = detect_rio_pair_mismatch(tS1, tS2, cal, params)
%DETECT_RIO_PAIR_MISMATCH r_io event if traversal counterpart is missing.
% Uses calibrated expected travel times (T12_LR, T12_RL).
% Output: event times t_io (seconds) and binary r_io (=1).

if nargin < 4 || isempty(params), params = struct(); end
if ~isfield(params,'ioMargin_s'), params.ioMargin_s = 0.6; end  % tolerance window

tS1 = sort(tS1(:));
tS2 = sort(tS2(:));

T12_LR = cal.T12_LR;
T12_RL = cal.T12_RL;

m = params.ioMargin_s;

% Helper: is there any event in b within [a+T-m, a+T+m]?
hasMatch = @(a, b, T) any(b >= (a + T - m) & b <= (a + T + m));

% S1 -> expect S2 after T12_LR
miss12 = false(size(tS1));
if isfinite(T12_LR) && T12_LR > 0
    for i = 1:numel(tS1)
        miss12(i) = ~hasMatch(tS1(i), tS2, T12_LR);
    end
end

% S2 -> expect S1 after T12_RL
miss21 = false(size(tS2));
if isfinite(T12_RL) && T12_RL > 0
    for i = 1:numel(tS2)
        miss21(i) = ~hasMatch(tS2(i), tS1, T12_RL);
    end
end

% Place alarm at "deadline" = expected arrival + margin
t_io = [];
if any(miss12)
    t_io = [t_io; tS1(miss12) + T12_LR + m];
end
if any(miss21)
    t_io = [t_io; tS2(miss21) + T12_RL + m];
end

t_io = sort(t_io);
r_io = ones(size(t_io)); % binary
end
