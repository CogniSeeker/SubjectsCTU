function p = conveyor_alarm_defaults(p)
%CONVEYOR_ALARM_DEFAULTS Parameters for threshold-based alarming.

if nargin < 1 || isempty(p), p = struct(); end

if ~isfield(p,'t_ignore_s'), p.t_ignore_s = 5.0; end

% Thresholds (residuals are normalized ~ "sigma units" in your code)
if ~isfield(p,'thr_r_tick'), p.thr_r_tick = 2.0; end
if ~isfield(p,'thr_r_trav'), p.thr_r_trav = 3.0; end

% Higher thresholds for sub-classification (e.g., stopped vs just slow/fast)
if ~isfield(p,'thr_r_tick_hi'), p.thr_r_tick_hi = 4.0; end
if ~isfield(p,'thr_r_trav_hi'), p.thr_r_trav_hi = 6.0; end

% Hysteresis thresholds for state-style alarms (used in build_alarm_states)
% Off-thresholds are slightly lower so the alarm must "recover".
if ~isfield(p,'thr_r_tick_off'), p.thr_r_tick_off = 0.8 * p.thr_r_tick; end
if ~isfield(p,'thr_r_tick_hi_off'), p.thr_r_tick_hi_off = 0.8 * p.thr_r_tick_hi; end
if ~isfield(p,'thr_r_trav_off'), p.thr_r_trav_off = 0.8 * p.thr_r_trav; end
if ~isfield(p,'thr_r_trav_hi_off'), p.thr_r_trav_hi_off = 0.8 * p.thr_r_trav_hi; end

% Time association window: residual considered active for hold_s after it fires
% (needed to combine async residuals for classification)
if ~isfield(p,'hold_s'),     p.hold_s = 0.5; end

if ~isfield(p,'refractory_s'), p.refractory_s = 2.0; end  % minimum time between different fault classes

% Optional: ignore NaNs
if ~isfield(p,'ignore_nan'), p.ignore_nan = true; end

% Experiment/debug: ignore tick-disconnect state (e.g., sensor unplugged by mistake)
if ~isfield(p,'ignore_tick_disc'), p.ignore_tick_disc = false; end
end
