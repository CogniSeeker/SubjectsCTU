function plot_data(filename, layout, t_end)

%PLOT_DATA Plot selected signals from a timetable MAT-file.
%
% Usage:
%   plot_data();
%   plot_data("data_example_file.mat");
%   plot_data("data_example_file.mat", "single");   % one figure, stacked subplots
%   plot_data("data_example_file.mat", "separate"); % one figure per signal
%   plot_data("data_example_file.mat", "single", 13); % plot only first 13 s
%
% Notes:
% - Only plots signals expected from the recording workflow (v_i0..v_i5 if present).
% - Time axis uses seconds from start based on timetable RowTimes.

if nargin < 1 || (isstring(filename) && strlength(filename)==0)
    filename = "data_example_file.mat";
end

if nargin < 2 || isempty(layout)
    layout = "separate";
end

if nargin < 3
    t_end = [];
end

if islogical(layout)
    if layout
        layout = "single";
    else
        layout = "separate";
    end
end

layout = string(layout);
layout = lower(strtrim(layout));
if ~(layout == "single" || layout == "separate")
    error('plot_data:BadLayout', 'layout must be "single" or "separate" (or a logical).');
end

thisDir = fileparts(mfilename('fullpath'));

% Make sure helper folders are visible
addpath(fullfile(thisDir, 'helpers'));
addpath(fullfile(thisDir, 'conveyor_res_helpers'));

TT = load_first_timetable(resolve_path(filename, thisDir));

rt = TT.Properties.RowTimes;
t_s = seconds(rt - rt(1));

% Optional time window (in seconds from start).
t_end_s = [];
if ~isempty(t_end)
    if isduration(t_end)
        t_end_s = seconds(t_end);
    else
        t_end_s = double(t_end);
    end
end
useWindow = ~isempty(t_end_s) && isfinite(t_end_s) && (t_end_s > 0);

% Plot only signals expected from recording (if present)
sigNames = ["v_i0","v_i1","v_i2","v_i3","v_i4","v_i5"];
sigTitles = [
    "Sensor S1 (v_i0)", ...
    "Sensor S2 (v_i1)", ...
    "Direction / motor proxy (v_i2)", ...
    "Tick (v_i3)", ...
    "Motor terminal (v_i4)", ...
    "Lamp (v_i5)" ...
];

present = ismember(sigNames, string(TT.Properties.VariableNames));
sigNames = sigNames(present);
sigTitles = sigTitles(present);

if isempty(sigNames)
    error('plot_data:NoSignals', 'None of v_i0..v_i5 were found in the timetable.');
end

% Force a readable light style regardless of MATLAB theme settings.
% (Do this per-figure/per-axes to avoid changing user's global defaults.)
lightFigColor = 'w';
lightAxColor = 'w';
axisTextColor = [0 0 0];
gridColor = [0.15 0.15 0.15];

    function apply_light_axes(ax)
        try
            ax.Color = lightAxColor;
            ax.XColor = axisTextColor;
            ax.YColor = axisTextColor;
            ax.ZColor = axisTextColor;
            ax.GridColor = gridColor;
            ax.MinorGridColor = gridColor;
            ax.GridAlpha = 0.15;
            ax.MinorGridAlpha = 0.08;
        catch
        end
    end

if layout == "single"
    fig = figure('Name', 'Recorded signals', 'Color', lightFigColor);
    set(gcf, 'Position', [100 80 1200 900]);
    tl = tiledlayout(numel(sigNames), 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    try
        tl.TileSpacing = 'compact';
        tl.Padding = 'compact';
    catch
    end

    for k = 1:numel(sigNames)
        ax = nexttile(tl);
        y = TT.(sigNames(k));

        if useWindow
            mask = (t_s <= t_end_s);
            plot(ax, t_s(mask), y(mask), 'LineWidth', 1.1);
            xlim(ax, [0, t_end_s]);
        else
            plot(ax, t_s, y, 'LineWidth', 1.1);
        end
        grid(ax, 'on');
        grid(ax, 'minor');
        apply_light_axes(ax);
        title(ax, sigTitles(k), 'Interpreter', 'none', 'Color', axisTextColor, 'FontWeight', 'normal');
        ylabel(ax, sprintf('%s [V]', sigNames(k)), 'Interpreter', 'none', 'Color', axisTextColor, 'FontWeight', 'normal');
        % Keep x-axis tick labels on every subplot (useful when figure is small).
        if k == numel(sigNames)
            xlabel(ax, 't [s]', 'Color', axisTextColor, 'FontWeight', 'normal');
        end
    end
else
    for k = 1:numel(sigNames)
        name = sigNames(k);
        y = TT.(name);

        fig = figure('Name', char(sigTitles(k)), 'Color', lightFigColor);
        set(gcf, 'Position', [100 100 1200 350]);

        if useWindow
            mask = (t_s <= t_end_s);
            plot(t_s(mask), y(mask), 'LineWidth', 1.1);
            xlim([0, t_end_s]);
        else
            plot(t_s, y, 'LineWidth', 1.1);
        end
        grid on;
        grid minor;

        apply_light_axes(gca);

        xlabel('t [s]', 'Color', axisTextColor, 'FontWeight', 'normal');
        ylabel(sprintf('%s [V]', name), 'Interpreter', 'none', 'Color', axisTextColor, 'FontWeight', 'normal');
        title(sigTitles(k), 'Interpreter', 'none', 'Color', axisTextColor, 'FontWeight', 'normal');
    end
end

end

function p = resolve_path(filename, baseDir)
% If filename is relative, resolve relative to baseDir.
if isstring(filename)
    filename = char(filename);
end

if isempty(filename)
    p = baseDir;
    return;
end

if exist(filename, 'file') == 2
    p = filename;
    return;
end

p2 = fullfile(baseDir, filename);
if exist(p2, 'file') == 2
    p = p2;
    return;
end

error('plot_data:FileNotFound', 'File not found: %s', filename);
end
