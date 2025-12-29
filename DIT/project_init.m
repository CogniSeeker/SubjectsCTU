% Ensure helper functions are on path
addpath(fullfile(fileparts(mfilename('fullpath')), 'conveyor_res_helpers'));
addpath(fullfile(fileparts(mfilename('fullpath')), 'conveyor_faults'));
addpath(fullfile(fileparts(mfilename('fullpath')), 'helpers'));
addpath(fullfile(fileparts(mfilename('fullpath')), 'core'));

% Load data to test conveyor fault detection on
data = load_data("data/data_minus_tick.mat");