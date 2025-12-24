function alarms = conveyor_fault_alarms_from_residuals(res, feat, cal, p)
%CONVEYOR_FAULT_ALARMS_FROM_RESIDUALS Main entry: residuals -> alarm table.

p = conveyor_alarm_defaults(p);

ev = extract_residual_events(res, feat, cal, p);
alarms = classify_at_times(ev, p);
end
