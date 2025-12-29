function TT = unwrap_timetable(x)
%UNWRAP_TIMETABLE Accept a timetable or unwrap a timetable from a struct (e.g., load() output).
%
% Usage:
%   TT = unwrap_timetable(TT);
%   TT = unwrap_timetable(S);   % where S = load(...)

if istimetable(x)
    TT = x;
    return;
end

if isstruct(x)
    % Prefer a field named "data" if it contains a timetable
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

error('unwrap_timetable:BadInput', 'Expected a timetable or a struct containing a timetable, got %s.', class(x));
end
