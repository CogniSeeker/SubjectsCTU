function T = alarm_states_table(S)
%ALARM_STATES_TABLE Convert build_alarm_states() output into a printable table.
%
% The table is filtered to t >= S.t_ignore_s (using S.mask).

if ~isstruct(S) || ~isfield(S,'t_s')
    error('alarm_states_table:BadInput', 'Expected a struct from build_alarm_states with field t_s.');
end

t = S.t_s(:);
if isfield(S,'mask') && ~isempty(S.mask)
    mask = logical(S.mask(:));
else
    mask = true(size(t));
end

sel = mask;

% Helper to fetch logical vector aligned to t
getL = @(name) get_logical_field(S, name, numel(t));
getN = @(name) get_numeric_field(S, name, numel(t));

T = table();
T.t_s = t(sel);

% Disconnected states
if isfield(S,'motor_disc'), x = getL('motor_disc'); T.motor_disc = x(sel); end
if isfield(S,'tick_disc'),  x = getL('tick_disc');  T.tick_disc  = x(sel); end
if isfield(S,'s1_disc'),    x = getL('s1_disc');    T.s1_disc    = x(sel); end
if isfield(S,'s2_disc'),    x = getL('s2_disc');    T.s2_disc    = x(sel); end
if isfield(S,'lamps_disc'), x = getL('lamps_disc'); T.lamps_disc = x(sel); end

% Persistent residual states
if isfield(S,'tick_state'),    x = getL('tick_state');    T.tick    = x(sel); end
if isfield(S,'tick_hi_state'), x = getL('tick_hi_state'); T.tick_hi = x(sel); end
if isfield(S,'trav_state'),    x = getL('trav_state');    T.trav    = x(sel); end
if isfield(S,'trav_hi_state'), x = getL('trav_hi_state'); T.trav_hi = x(sel); end
if isfield(S,'dir_state'),     x = getL('dir_state');     T.dir     = x(sel); end

% NaN/availability indicators
if isfield(S,'tick_nan'), x = getL('tick_nan'); T.tick_nan = x(sel); end
if isfield(S,'trav_known'), x = getL('trav_known'); T.trav_known = x(sel); end
if isfield(S,'dir_known'),  x = getL('dir_known');  T.dir_known  = x(sel); end
if isfield(S,'dir_nan_event_latest'), x = getL('dir_nan_event_latest'); T.dir_nan_event = x(sel); end

% Optional: latest values for debugging
if isfield(S,'tick_val'), x = getN('tick_val'); T.tick_val = x(sel); end
if isfield(S,'trav_latest'), x = getN('trav_latest'); T.trav_latest = x(sel); end
if isfield(S,'dir_latest'), x = getN('dir_latest'); T.dir_latest = x(sel); end

end

function x = get_logical_field(S, name, n)
if ~isfield(S, name)
    x = false(n,1);
    return;
end
x = S.(name);
if isempty(x)
    x = false(n,1);
    return;
end
x = logical(x(:));
if numel(x) ~= n
    error('alarm_states_table:BadSize', 'Field %s has wrong length (%d != %d).', name, numel(x), n);
end
end

function x = get_numeric_field(S, name, n)
if ~isfield(S, name)
    x = nan(n,1);
    return;
end
x = S.(name);
if isempty(x)
    x = nan(n,1);
    return;
end
x = double(x(:));
if numel(x) ~= n
    error('alarm_states_table:BadSize', 'Field %s has wrong length (%d != %d).', name, numel(x), n);
end
end
