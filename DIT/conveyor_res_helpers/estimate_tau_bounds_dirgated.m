function [tau_min, tau_max] = estimate_tau_bounds_dirgated(tS1, tS2, t, dir, t_flip, tauSearchMax)
dt = [];

% S1 events valid when approaching left end (dir=-1)
for i = 1:numel(tS1)
    k = find(t <= tS1(i), 1, 'last');
    if isempty(k) || dir(k) ~= -1, continue; end
    j = find(t_flip > tS1(i), 1, 'first');
    if isempty(j), continue; end
    dti = t_flip(j) - tS1(i);
    if dti > 0 && dti < tauSearchMax, dt(end+1,1) = dti; end %#ok<AGROW>
end

% S2 events valid when approaching right end (dir=+1)
for i = 1:numel(tS2)
    k = find(t <= tS2(i), 1, 'last');
    if isempty(k) || dir(k) ~= +1, continue; end
    j = find(t_flip > tS2(i), 1, 'first');
    if isempty(j), continue; end
    dti = t_flip(j) - tS2(i);
    if dti > 0 && dti < tauSearchMax, dt(end+1,1) = dti; end %#ok<AGROW>
end

if numel(dt) >= 5
    tau_min = quantile(dt, 0.05);
    tau_max = quantile(dt, 0.95);
else
    tau_min = 0.05;
    tau_max = 1.00;
end
end
