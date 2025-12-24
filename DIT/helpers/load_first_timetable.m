function TT = load_first_timetable(filename)
%LOAD_FIRST_TIMETABLE Load a .mat file and return the first timetable found.
%
% If a variable named "data" exists and is a timetable, it is preferred.
%
% Example:
%   TT = load_first_timetable("data/data_15s.mat");

S = load(filename);

% Prefer a variable named "data" if present
if isfield(S, 'data') && istimetable(S.data)
    TT = S.data;
    return;
end

fn = fieldnames(S);
for k = 1:numel(fn)
    v = S.(fn{k});
    if istimetable(v)
        TT = v;
        return;
    end
end

error("load_first_timetable:NoTimetable", "No timetable found in %s.", filename);
end
