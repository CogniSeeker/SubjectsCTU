function [h, lab] = plot_rtrav(res)
%PLOT_RTRAV Plot travel residual events (LR/RL) and return handles/labels.

h = gobjects(0);
lab = {};

if isfield(res,'LR') && isfield(res.LR,'t_start_s') && isfield(res.LR,'r_trav') ...
        && ~isempty(res.LR.t_start_s) && ~isempty(res.LR.r_trav)
    h(end+1) = stem(res.LR.t_start_s, res.LR.r_trav, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'LR (S1->S2)'; %#ok<AGROW>
end

if isfield(res,'RL') && isfield(res.RL,'t_start_s') && isfield(res.RL,'r_trav') ...
        && ~isempty(res.RL.t_start_s) && ~isempty(res.RL.r_trav)
    h(end+1) = stem(res.RL.t_start_s, res.RL.r_trav, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'RL (S2->S1)'; %#ok<AGROW>
end
end
