function plot_data(filename, layout)

%PLOT_DATA Plot selected signals from a timetable MAT-file.
%
% Usage:
%   plot_data();
%   plot_data("data_example_file.mat");
%   plot_data("data_example_file.mat", "single");   % one figure, stacked subplots
%   plot_data("data_example_file.mat", "separate"); % one figure per signal
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

if layout == "single"
    figure('Name', 'Recorded signals', 'Color', 'w');
    set(gcf, 'Position', [100 80 1200 900]);
    tl = tiledlayout(numel(sigNames), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    for k = 1:numel(sigNames)
        ax = nexttile(tl);
        y = TT.(sigNames(k));
        plot(ax, t_s, y, 'LineWidth', 1.1);
        grid(ax, 'on');
        grid(ax, 'minor');
        title(ax, sigTitles(k), 'Interpreter', 'none');
        ylabel(ax, sprintf('%s [V]', sigNames(k)), 'Interpreter', 'none');
        if k == numel(sigNames)
            xlabel(ax, 't [s]');
        else
            ax.XTickLabel = [];
        end
    end
else
    for k = 1:numel(sigNames)
        name = sigNames(k);
        y = TT.(name);

        figure('Name', char(sigTitles(k)), 'Color', 'w');
        set(gcf, 'Position', [100 100 1200 350]);

        plot(t_s, y, 'LineWidth', 1.1);
        grid on;
        grid minor;

        xlabel('t [s]');
        ylabel(sprintf('%s [V]', name), 'Interpreter', 'none');
        title(sigTitles(k), 'Interpreter', 'none');
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
