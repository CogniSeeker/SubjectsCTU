function [h, lab] = plot_rdir(res)
%PLOT_RDIR Plot direction residual events and return handles/labels.

h = gobjects(0);
lab = {};

    function [tt, xx] = finite_only(tt, xx)
        if isempty(tt) || isempty(xx)
            tt = []; xx = [];
            return;
        end
        tt = tt(:); xx = xx(:);
        n = min(numel(tt), numel(xx));
        tt = tt(1:n);
        xx = xx(1:n);
        ok = isfinite(tt) & isfinite(xx);
        tt = tt(ok);
        xx = xx(ok);
    end

if isfield(res,'r_dir_S1_t_s') && isfield(res,'r_dir_S1') && ~isempty(res.r_dir_S1_t_s)
    [t1, x1] = finite_only(res.r_dir_S1_t_s, res.r_dir_S1);
    if ~isempty(t1)
        h(end+1) = stem(t1, x1, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
        lab{end+1} = 'Sensor S1 end events'; %#ok<AGROW>
    end
end

if isfield(res,'r_dir_S2_t_s') && isfield(res,'r_dir_S2') && ~isempty(res.r_dir_S2_t_s)
    [t2, x2] = finite_only(res.r_dir_S2_t_s, res.r_dir_S2);
    if ~isempty(t2)
        h(end+1) = stem(t2, x2, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
        lab{end+1} = 'Sensor S2 end events'; %#ok<AGROW>
    end
end
end
