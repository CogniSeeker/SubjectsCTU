function [t_L1, r_L1, t_L2, r_L2] = detect_rio_lamp_events(t, v_lamp, cal, params)
%DETECT_RIO_LAMP_EVENTS Detect lamp-related IO faults from lamp voltage v_i5.
% L1 disconnected: sustained v_lamp < lampLowV
% L2 disconnected: sustained drop below (cal.lamp_mu - lampL2DropV), but not near zero

t = t(:);
v_lamp = v_lamp(:);

t_L1 = []; r_L1 = [];
t_L2 = []; r_L2 = [];

if isempty(t) || isempty(v_lamp) || numel(t) ~= numel(v_lamp)
    return;
end

if ~isfield(cal,'lamp_mu') || ~isfinite(cal.lamp_mu)
    % If calibration lacks lamp_mu, only do L1(near-zero) detection.
    cal.lamp_mu = median(v_lamp(isfinite(v_lamp)), 'omitnan');
end

% Conditions
cond_L1 = isfinite(v_lamp) & (v_lamp < params.lampLowV);

% L2 drop: below baseline by at least lampL2DropV, excluding near-zero condition
cond_L2 = isfinite(v_lamp) & ~cond_L1 & (v_lamp < (cal.lamp_mu - params.lampL2DropV));

% Convert runs to events
t_L1 = runs_to_event_times(t, cond_L1, params.lampLowMinDur, params.lampEventMinGap);
t_L2 = runs_to_event_times(t, cond_L2, params.lampL2MinDur,  params.lampEventMinGap);

r_L1 = ones(size(t_L1)); % binary
r_L2 = ones(size(t_L2)); % binary
end
