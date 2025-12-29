function [h, lab] = plot_rio(res)
%PLOT_RIO Plot IO residual events (lamp L1/L2 + pair mismatch).

h = gobjects(0);
lab = {};

if isfield(res,'r_io_L1_t_s') && isfield(res,'r_io_L1') && ~isempty(res.r_io_L1_t_s)
    h(end+1) = stem(res.r_io_L1_t_s, res.r_io_L1, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'IO: Lamp L1 open'; %#ok<AGROW>
end

if isfield(res,'r_io_L2_t_s') && isfield(res,'r_io_L2') && ~isempty(res.r_io_L2_t_s)
    h(end+1) = stem(res.r_io_L2_t_s, res.r_io_L2, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'IO: Lamp L2 open'; %#ok<AGROW>
end

if isfield(res,'r_io_pair_t_s') && isfield(res,'r_io_pair') && ~isempty(res.r_io_pair_t_s)
    h(end+1) = stem(res.r_io_pair_t_s, res.r_io_pair, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'IO: Pair mismatch'; %#ok<AGROW>
end
end
