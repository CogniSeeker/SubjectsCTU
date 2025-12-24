function t_ev = runs_to_event_times(t, cond, minDur, minGap)
%RUNS_TO_EVENT_TIMES Convert boolean runs to event times at run start.
% Keeps only runs lasting >= minDur and debounces by minGap.

t = t(:);
cond = logical(cond(:));

if isempty(t) || isempty(cond) || numel(t) ~= numel(cond)
    t_ev = [];
    return;
end

d = diff([false; cond; false]);
starts = find(d == 1);
ends   = find(d == -1) - 1;

t_ev = [];
for k = 1:numel(starts)
    i0 = starts(k);
    i1 = ends(k);
    if (t(i1) - t(i0)) >= minDur
        t_ev(end+1,1) = t(i0); %#ok<AGROW>
    end
end

% Debounce events
if ~isempty(t_ev) && minGap > 0
    keep = [true; diff(t_ev) >= minGap];
    t_ev = t_ev(keep);
end
end
