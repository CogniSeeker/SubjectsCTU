% TT = load_first_timetable("data/data_minus_motor.mat");
% If you ran DIT/load_data.m, variable "data" should already be a timetable.
% If "data" is still a struct (e.g., data = load(...)), unwrap it.
TT = unwrap_timetable(data);

params = struct();

[res_test, feat_test] = calc_residuals(TT, cal150, params);

p = struct();

alarms = conveyor_fault_alarms_from_residuals(res_test, feat_test, cal150, p);
disp(pretty_alarm_table(alarms))

% Also print the persistent state table (continuous-ish view)
S = build_alarm_states(res_test, feat_test, cal150, p);
Tstates = alarm_states_table(S);
disp(pretty_alarm_table(Tstates))

% Plot all available residuals (including any added in the future)
plot_all_residuals(res_test, feat_test, 'Test', cal150, p);

function T = pretty_alarm_table(T)
%PRETTY_ALARM_TABLE Make logical columns more readable in Command Window.
% Shows true as T, keeps false as false.

vars = T.Properties.VariableNames;
for k = 1:numel(vars)
	v = T.(vars{k});
	if islogical(v)
		T.(vars{k}) = categorical(v, [false true], {'false','T'});
	end
end
end