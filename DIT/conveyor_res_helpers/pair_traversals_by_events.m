function [LR, RL] = pair_traversals_by_events(tS1, tS2, t, dir, T12_min, T12_max)
% Pair end events by time order; classify direction by dominant dir between events.

tS1 = tS1(:); tS2 = tS2(:);
times  = [tS1; tS2];
labels = [ones(size(tS1)); 2*ones(size(tS2))]; % 1=S1, 2=S2

[times, ord] = sort(times);
labels = labels(ord);

LR_t0 = []; LR_T = [];
RL_t0 = []; RL_T = [];

for i = 1:numel(times)-1
    % find next event of the other sensor
    j = i + find(labels(i+1:end) ~= labels(i), 1, 'first');
    if isempty(j), continue; end

    dt = times(j) - times(i);
    if ~(dt >= T12_min && dt <= T12_max)
        continue;
    end

    % dominant direction in (times(i), times(j))
    in = (t >= times(i)) & (t <= times(j));
    d = dir(in);
    d = d(d ~= 0);
    if isempty(d), continue; end
    ddom = sign(median(d)); % robust dominant sign

    if labels(i) == 1 && labels(j) == 2 && ddom == +1
        LR_t0(end+1,1) = times(i);
        LR_T(end+1,1)  = dt;
    elseif labels(i) == 2 && labels(j) == 1 && ddom == -1
        RL_t0(end+1,1) = times(i);
        RL_T(end+1,1)  = dt;
    end
end

LR = struct('t_start_s', LR_t0, 'T_meas_s', LR_T);
RL = struct('t_start_s', RL_t0, 'T_meas_s', RL_T);
end
