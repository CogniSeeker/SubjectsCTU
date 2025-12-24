function TT = load_data(filename)
%LOAD_DATA Convenience wrapper to load the default dataset (timetable).
%
% Usage:
%   TT = load_data();
%   TT = load_data("data/data_15s.mat");

if nargin < 1 || (isstring(filename) && strlength(filename)==0)
	filename = "data/data_minus_motor.mat";
end

TT = load_first_timetable(filename);
end