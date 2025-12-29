function [h, lab] = plot_rdir(res)
%PLOT_RDIR Plot direction residual events and return handles/labels.

h = gobjects(0);
lab = {};

if isfield(res,'r_dir_S1_t_s') && isfield(res,'r_dir_S1') && ~isempty(res.r_dir_S1_t_s)
    h(end+1) = stem(res.r_dir_S1_t_s, res.r_dir_S1, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S1 end events'; %#ok<AGROW>
end

if isfield(res,'r_dir_S2_t_s') && isfield(res,'r_dir_S2') && ~isempty(res.r_dir_S2_t_s)
    h(end+1) = stem(res.r_dir_S2_t_s, res.r_dir_S2, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S2 end events'; %#ok<AGROW>
end
end
