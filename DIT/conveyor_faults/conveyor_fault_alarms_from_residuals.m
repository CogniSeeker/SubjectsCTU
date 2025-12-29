function alarms = conveyor_fault_alarms_from_residuals(res, feat, cal, p)
%CONVEYOR_FAULT_ALARMS_FROM_RESIDUALS Main entry: residuals -> alarm table.

p = conveyor_alarm_defaults(p);

% ev = extract_residual_events(res, feat, cal, p);
% alarms = classify_at_times(ev, p);

% New pipeline: classify based on persistent states (not raw event spikes)
S = build_alarm_states(res, feat, cal, p);
alarms = classify_states_at_times(S, p);
end
