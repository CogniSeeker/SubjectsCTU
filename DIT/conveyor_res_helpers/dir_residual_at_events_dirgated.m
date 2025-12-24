function rdir = dir_residual_at_events_dirgated(tS, t, dir, t_flip, tau_min, tau_max, requiredDir)
%DIR_RESIDUAL_AT_EVENTS_DIRGATED Evaluate r_dir only when direction matches.

tS = tS(:); t_flip = t_flip(:);
rdir = nan(size(tS));

for i = 1:numel(tS)
    k = find(t <= tS(i), 1, 'last'); % direction just before event
    if isempty(k) || dir(k) ~= requiredDir
        rdir(i) = NaN; % not applicable
        continue;
    end

    tf = t_flip(find(t_flip > tS(i), 1, 'first'));
    if isempty(tf)
        rdir(i) = 1;
        continue;
    end

    dtv = tf - tS(i);
    rdir(i) = ~(dtv >= tau_min && dtv <= tau_max);
end
end
