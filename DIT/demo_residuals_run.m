% demo_residuals_run.m
% Demo: load your .mat and compute residuals (no hysteresis/persistence/etc.)

TT15  = load_first_timetable("data/data_15s.mat");
TT150 = load_first_timetable("data/data_150s.mat");

params = struct();
params.W = 1.0;
params.S = 0.5;

[res15, cal15, feat15]   = conveyor_residuals(TT15, params);
[res150, cal150, feat150] = conveyor_residuals(TT150, params);

disp(cal15)
disp(cal150)

% -----------------------
% r_tick plots
% -----------------------
% figure;
% plot(feat15.win_center_s, res15.r_tick); grid on;
% xlabel('t [s]'); ylabel('r_{tick}'); title('r_{tick} (15 s)');

figure;
plot(feat150.win_center_s, res150.r_tick); grid on;
xlabel('t [s]'); ylabel('r_{tick}'); title('r_{tick} (150 s)');

% -----------------------
% r_trav plots
% -----------------------
% figure;
% [h, lab] = plot_rtrav(res15);
% grid on; xlabel('t [s]'); ylabel('r_{trav}');
% if ~isempty(h)
%     legend(h, lab, 'Interpreter', 'none');
% end
% title('r_{trav} events (15 s)');

figure;
[h, lab] = plot_rtrav(res150);
grid on; xlabel('t [s]'); ylabel('r_{trav}');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('r_{trav} events (150 s)');

% -----------------------
% r_dir plots
% -----------------------
% figure;
% [h, lab] = plot_rdir(res15);
% grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
% if ~isempty(h)
%     legend(h, lab, 'Interpreter', 'none');
% end
% title('r_{dir} events (15 s)');

figure;
[h, lab] = plot_rdir(res150);
grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('r_{dir} events (150 s)');


% ==================================

[res_test, feat_test] = conveyor_residuals_apply_cal(TT150, cal150, params);

figure;
plot(feat_test.win_center_s, res_test.r_tick); grid on;
xlabel('t [s]'); ylabel('r_{tick}'); title('Test: r_{tick} (150 s)');

figure;
[h, lab] = plot_rtrav(res_test);
grid on; xlabel('t [s]'); ylabel('r_{trav}');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('Test: r_{trav} events (150 s)');

figure;
[h, lab] = plot_rdir(res_test);
grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('Test: r_{dir} events (150 s)');

% =========================
% Local helper functions
% =========================
function [h, lab] = plot_rtrav(res)
% Returns handles and labels for legend, robust to empty series.

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

function [h, lab] = plot_rdir(res)
% Supports both old field names (A/B) and new (S1/S2).
h = gobjects(0);
lab = {};

if isfield(res,'r_dir_S1_t_s') && isfield(res,'r_dir_S1') && ~isempty(res.r_dir_S1_t_s)
    h(end+1) = stem(res.r_dir_S1_t_s, res.r_dir_S1, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S1 end events'; %#ok<AGROW>
elseif isfield(res,'r_dir_A_t_s') && isfield(res,'r_dir_A') && ~isempty(res.r_dir_A_t_s)
    h(end+1) = stem(res.r_dir_A_t_s, res.r_dir_A, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor A events'; %#ok<AGROW>
end

if isfield(res,'r_dir_S2_t_s') && isfield(res,'r_dir_S2') && ~isempty(res.r_dir_S2_t_s)
    h(end+1) = stem(res.r_dir_S2_t_s, res.r_dir_S2, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S2 end events'; %#ok<AGROW>
elseif isfield(res,'r_dir_B_t_s') && isfield(res,'r_dir_B') && ~isempty(res.r_dir_B_t_s)
    h(end+1) = stem(res.r_dir_B_t_s, res.r_dir_B, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor B events'; %#ok<AGROW>
end
end

function TT = load_first_timetable(filename)
S = load(filename);
fn = fieldnames(S);
for k = 1:numel(fn)
    v = S.(fn{k});
    if istimetable(v)
        TT = v;
        return;
    end
end
error("No timetable found in %s.", filename);
end
