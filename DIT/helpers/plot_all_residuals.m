function plot_all_residuals(res, feat, titlePrefix)
%PLOT_ALL_RESIDUALS Plot all residuals available in calc_residuals output.
%
%   plot_all_residuals(res, feat, titlePrefix)
%
% This function produces figures for the current residual set.
% It plots the core residuals (r_tick, r_trav, r_dir) and then scans for any
% other fields starting with "r_" (including *_disc) and plots them.
%
% Legacy residual plots (r_io_*, r_pwr) are intentionally not shown here.

if nargin < 3
    titlePrefix = '';
end

handled = containers.Map('KeyType','char','ValueType','logical');

    function t = mkTitle(s)
        if isempty(titlePrefix)
            t = s;
        else
            t = sprintf('%s: %s', titlePrefix, s);
        end
    end

    function markHandled(name)
        if ~isKey(handled, name)
            handled(name) = true;
        end
    end

% -----------------------
% r_tick
% -----------------------
if isfield(res,'r_tick')
    t_tick = [];
    if isfield(res,'r_tick_t_s')
        t_tick = res.r_tick_t_s;
    elseif nargin >= 2 && isfield(feat,'win_center_s')
        t_tick = feat.win_center_s;
    end

    if ~isempty(t_tick) && ~isempty(res.r_tick)
        figure;
        plot(t_tick, res.r_tick); grid on;
        xlabel('t [s]'); ylabel('r_{tick}');
        title(mkTitle('r_{tick}'));
        markHandled('r_tick');
        markHandled('r_tick_t_s');
    end
end

% -----------------------
% r_trav
% -----------------------
figure;
[h, lab] = plot_rtrav(res);
grid on; xlabel('t [s]'); ylabel('r_{trav}');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title(mkTitle('r_{trav} events'));
markHandled('LR');
markHandled('RL');

% -----------------------
% r_dir
% -----------------------
figure;
[h, lab] = plot_rdir(res);
grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title(mkTitle('r_{dir} events'));
markHandled('r_dir_S1');
markHandled('r_dir_S2');
markHandled('r_dir_S1_t_s');
markHandled('r_dir_S2_t_s');

% -----------------------
% sensors disconnected
% -----------------------
if isfield(res,'r_s1_disc_t_s') && isfield(res,'r_s1_disc') && ~isempty(res.r_s1_disc_t_s)
    figure;
    plot(res.r_s1_disc_t_s, double(res.r_s1_disc)); grid on;
    xlabel('t [s]'); ylabel('r_{s1\_disc}');
    title(mkTitle('r_{s1\_disc} (0/1)'));
    markHandled('r_s1_disc');
    markHandled('r_s1_disc_t_s');
end

if isfield(res,'r_s2_disc_t_s') && isfield(res,'r_s2_disc') && ~isempty(res.r_s2_disc_t_s)
    figure;
    plot(res.r_s2_disc_t_s, double(res.r_s2_disc)); grid on;
    xlabel('t [s]'); ylabel('r_{s2\_disc}');
    title(mkTitle('r_{s2\_disc} (0/1)'));
    markHandled('r_s2_disc');
    markHandled('r_s2_disc_t_s');
end

% -----------------------
% Scan and plot remaining r_* residuals (excluding legacy)
% -----------------------
legacyPrefixes = {"r_io", "r_pwr"};

fields = fieldnames(res);
for k = 1:numel(fields)
    name = fields{k};
    if ~ischar(name) || ~startsWith(name, 'r_')
        continue;
    end
    if endsWith(name, '_t_s')
        continue;
    end

    % Skip legacy residual families
    isLegacy = false;
    for j = 1:numel(legacyPrefixes)
        if startsWith(name, legacyPrefixes{j})
            isLegacy = true;
            break;
        end
    end
    if isLegacy
        continue;
    end

    if isKey(handled, name)
        continue;
    end

    x = res.(name);
    if isempty(x) || ~(isnumeric(x) || islogical(x))
        continue;
    end
    if ~isvector(x)
        continue;
    end
    x = x(:);

    t = [];
    tField = [name '_t_s'];
    if isfield(res, tField)
        t = res.(tField);
    elseif nargin >= 2 && isfield(feat, 'win_center_s') && numel(feat.win_center_s) == numel(x)
        t = feat.win_center_s;
    end
    if isempty(t)
        continue;
    end
    t = t(:);
    if numel(t) ~= numel(x)
        continue;
    end

    figure;
    plot(t, double(x)); grid on;
    xlabel('t [s]');
    ylabel(name, 'Interpreter', 'none');
    title(mkTitle(name), 'Interpreter', 'none');

    markHandled(name);
    if isfield(res, tField)
        markHandled(tField);
    end
end

end
