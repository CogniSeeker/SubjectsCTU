% demo_residuals_run.m
% Demo: load your .mat and compute residuals (no hysteresis/persistence/etc.)

TT15  = load_first_timetable("data/data_15s.mat");
TT150 = load_first_timetable("data/data_150s.mat");

params = struct();
params.W = 1.0;
params.S = 0.5;

% 1) Calibrate (no residual computation here)
[cal15,  ~] = calibrate(TT15,  params);
[cal150, ~] = calibrate(TT150, params);

% 2) Apply calibration to compute residuals
[res15,  feat15]  = calc_residuals(TT15,  cal15,  params);
[res150, feat150] = calc_residuals(TT150, cal150, params);

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

% -----------------------
% All other residuals (pwr/io/disconnect/etc.)
% -----------------------
plot_all_residuals(res150, feat150, '150 s');

