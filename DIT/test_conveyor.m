% TT = load_first_timetable("data/data_15s.mat");
% If you ran DIT/load_data.m, variable "data" should already be a timetable.
% If "data" is still a struct (e.g., data = load(...)), unwrap it.
TT = unwrap_timetable(data);

params = struct();
params.W = 2.0;
params.S = 0.5;

[res_test, feat_test] = conveyor_residuals_apply_cal(TT, cal150, params);

p = struct();

alarms = conveyor_fault_alarms_from_residuals(res_test, feat_test, cal150, p);
disp(alarms)

% % ==================================
% ==================================
% r_tick
% ==================================
figure;
plot(feat_test.win_center_s, res_test.r_tick); grid on;
xlabel('t [s]'); ylabel('r_{tick}'); title('Test: r_{tick}');

% ==================================
% r_trav
% ==================================
figure;
[h, lab] = plot_rtrav(res_test);
grid on; xlabel('t [s]'); ylabel('r_{trav}');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('Test: r_{trav} events');

% ==================================
% r_dir
% ==================================
figure;
[h, lab] = plot_rdir(res_test);
grid on; xlabel('t [s]'); ylabel('r_{dir} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('Test: r_{dir} events');

% ==================================
% r_pwr (binary over win centers)
% ==================================
if isfield(res_test,'r_pwr_t_s') && isfield(res_test,'r_pwr')
    figure;
    plot(res_test.r_pwr_t_s, double(res_test.r_pwr), '-'); grid on;
    xlabel('t [s]'); ylabel('r_{pwr} (0/1)');
    title('Test: r_{pwr}');
end

% ==================================
% r_io (lamp L1/L2 + pair mismatch)
% ==================================
figure;
[h, lab] = plot_rio(res_test);
grid on; xlabel('t [s]'); ylabel('r_{io} (0/1)');
if ~isempty(h)
    legend(h, lab, 'Interpreter', 'none');
end
title('Test: r_{io} events');

% sensors disconnected
figure;
plot(res_test.r_s1_disc_t_s, res_test.r_s1_disc); grid on;
xlabel('t [s]'); ylabel('r_{s1\_disc}'); title('Test: r_{s1\_disc} (0/1)');

figure;
plot(res_test.r_s2_disc_t_s, res_test.r_s2_disc); grid on;
xlabel('t [s]'); ylabel('r_{s2\_disc}'); title('Test: r_{s2\_disc} (0/1)');


% =========================
% Local helper functions
% =========================
function [h, lab] = plot_rtrav(res)
h = gobjects(0); lab = {};

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
h = gobjects(0); lab = {};

if isfield(res,'r_dir_S1_t_s') && isfield(res,'r_dir_S1') && ~isempty(res.r_dir_S1_t_s)
    h(end+1) = stem(res.r_dir_S1_t_s, res.r_dir_S1, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S1 end events'; %#ok<AGROW>
end

if isfield(res,'r_dir_S2_t_s') && isfield(res,'r_dir_S2') && ~isempty(res.r_dir_S2_t_s)
    h(end+1) = stem(res.r_dir_S2_t_s, res.r_dir_S2, '.', 'HandleVisibility','on'); hold on; %#ok<AGROW>
    lab{end+1} = 'Sensor S2 end events'; %#ok<AGROW>
end
end

function [h, lab] = plot_rio(res)
h = gobjects(0); lab = {};

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

function TT = unwrap_timetable(x)
% Accept timetable directly, or unwrap timetable from a struct created by load().
if istimetable(x)
    TT = x;
    return;
end

if isstruct(x)
    % Prefer field named "data" if it contains a timetable
    if isfield(x, 'data') && istimetable(x.data)
        TT = x.data;
        return;
    end

    fn = fieldnames(x);
    for k = 1:numel(fn)
        v = x.(fn{k});
        if istimetable(v)
            TT = v;
            return;
        end
    end
end

error('test_conveyor:BadInput', 'Expected a timetable or a struct containing a timetable, got %s.', class(x));
end