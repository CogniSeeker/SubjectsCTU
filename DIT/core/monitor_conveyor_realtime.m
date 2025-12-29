function monitor_conveyor_realtime(dev, cal, params)
%MONITOR_CONVEYOR_REALTIME Real-time NI DAQ monitor with fault lamps (no replay).

if nargin < 3, params = struct(); end
cfg = monitor_defaults(params);

% --- NI DAQ ---
dq = daq("ni");
dq.Rate = cfg.Fs;

addSE = @(chan,name) ( ...
    set(addinput(dq, dev, chan, "Voltage"), ...
        "Name", name, "TerminalConfig", "SingleEnded", "Range", [-10 10]) );

addSE("ai0","v_i0");
addSE("ai1","v_i1");
addSE("ai2","ai2_raw");
addSE("ai10","v_10");
addSE("ai3","v_i3");
addSE("ai4","v_i4");
addSE("ai5","v_i5");

dq.ScansAvailableFcnCount = max(ceil(cfg.cb_s * dq.Rate), ceil(dq.Rate/20));
dq.ScansAvailableFcn = @onScansAvailable;

% --- GUI ---
[ui, fig] = build_ui();

% --- state ---
buf = timetable();
t_last_ui = -Inf;

p_alarm = safe_alarm_defaults(struct());
cfg.res_params = conveyor_defaults(cfg.res_params);

% compute ignore horizon from calibration (fallback to cfg.t_ignore_s)
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
if isempty(T12)
    t_ignore = cfg.t_ignore_s;
else
    t_ignore = max(cfg.t_ignore_s, 2.0 * max(T12));
end
ui.ignore.Text = sprintf('ignore: %.2f s', t_ignore);

% start DAQ continuous (real-time)
start(dq, "continuous");
ui.status.Text = "RUNNING";
ui.status.FontColor = [0 0.5 0];

% keep alive
while isvalid(fig) && dq.Running
    pause(0.1);
end

% cleanup
try, if dq.Running, stop(dq); end, catch, end
try, dq.ScansAvailableFcn = []; catch, end

% =========================
% Callback
% =========================
function onScansAvailable(src, ~)
    if ~isvalid(fig)
        try, stop(src); end
        return;
    end

    tt = read(src, src.ScansAvailableFcnCount, "OutputFormat", "timetable");

    need = ["v_i0","v_i1","ai2_raw","v_10","v_i3","v_i4","v_i5"];
    if any(~ismember(need, string(tt.Properties.VariableNames)))
        ui.status.Text = "ERROR: missing DAQ channels";
        ui.status.FontColor = [0.8 0 0];
        return;
    end

    tt.v_i2 = tt.ai2_raw - tt.v_10;
    chunk = timetable(tt.Time, tt.v_i0, tt.v_i1, tt.v_i2, tt.v_i3, tt.v_i4, tt.v_i5, ...
        'VariableNames', {'v_i0','v_i1','v_i2','v_i3','v_i4','v_i5'});

    if isempty(buf), buf = chunk; else, buf = [buf; chunk]; end %#ok<AGROW>

    % trim buffer
    t_end = buf.Time(end);
    buf = buf(buf.Time >= (t_end - seconds(cfg.buffer_s)), :);

    t_now = seconds(buf.Time(end) - buf.Time(1));
    ui.time.Text = sprintf('%.3f', t_now);

    if (t_now - t_last_ui) < cfg.ui_s
        return;
    end
    t_last_ui = t_now;

    if height(buf) < max(ceil(cfg.min_buffer_s * cfg.Fs), 10)
        set_all_ok("BUFFERING");
        return;
    end

    % residuals
    try
        [res, feat] = calc_residuals(buf, cal, cfg.res_params);
    catch ME
        set_all_ok("RESIDUAL_ERROR");
        ui.class.Value = {ME.message};
        ui.status.Text = "RESIDUAL_ERROR";
        ui.status.FontColor = [0.8 0 0];
        return;
    end

    % alarms table
    try
        alarms = conveyor_fault_alarms_from_residuals(res, feat, cal, p_alarm);
    catch ME
        set_all_ok("ALARM_ERROR");
        ui.class.Value = {ME.message};
        ui.status.Text = "ALARM_ERROR";
        ui.status.FontColor = [0.8 0 0];
        return;
    end

    % ignore startup for ALL
    if t_now < t_ignore
        set_all_ok("STARTUP_IGNORE");
        return;
    end

    hold_s = getfield_with_default(p_alarm, "hold_s", 0.5);
    t0 = t_now - hold_s;
    activeMask = (alarms.t_s > t0) & (alarms.t_s <= t_now);

    flags.tick    = any_col(alarms, "tick",    activeMask);
    flags.trav    = any_col(alarms, "trav",    activeMask);
    flags.dir     = any_col(alarms, "dir",     activeMask);
    flags.io_pair = any_col(alarms, "io_pair", activeMask);
    flags.io_L1   = any_col(alarms, "io_L1",   activeMask);
    flags.io_L2   = any_col(alarms, "io_L2",   activeMask);
    flags.pwr     = any_col(alarms, "pwr",     activeMask);

    cls = choose_class(alarms, activeMask);

    set_lamp(ui.l_tick, flags.tick);
    set_lamp(ui.l_trav, flags.trav);
    set_lamp(ui.l_dir,  flags.dir);
    set_lamp(ui.l_iop,  flags.io_pair);
    set_lamp(ui.l_l1,   flags.io_L1);
    set_lamp(ui.l_l2,   flags.io_L2);
    set_lamp(ui.l_pwr,  flags.pwr);

    ui.class.Value = {char(cls)};

    isFault = (cls ~= "NONE") || flags.pwr;
    set_lamp(ui.l_overall, isFault);

    if isFault
        ui.status.Text = "FAULT";
        ui.status.FontColor = [0.8 0 0];
    else
        ui.status.Text = "OK";
        ui.status.FontColor = [0 0.5 0];
    end

    drawnow limitrate;
end

% =========================
% UI + helpers
% =========================
function [ui, fig] = build_ui()
    fig = uifigure('Name','Conveyor Monitor (REAL-TIME)','Position',[200 200 520 360]);
    fig.UserData.stop = false;

    gl = uigridlayout(fig, [10 3]);
    gl.RowHeight = {22,22,22,22,22,22,22,22,22,'1x'};
    gl.ColumnWidth = {170,80,'1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 6;

    ui = struct();

    % Row 1: time
    a = uilabel(gl,'Text','Time [s]:'); a.Layout.Row = 1; a.Layout.Column = 1;
    ui.time = uilabel(gl,'Text','0.000'); ui.time.Layout.Row = 1; ui.time.Layout.Column = 2;
    ui.ignore = uilabel(gl,'Text','ignore: --'); ui.ignore.Layout.Row = 1; ui.ignore.Layout.Column = 3;

    % Row 2: status + stop
    b = uilabel(gl,'Text','Status:'); b.Layout.Row = 2; b.Layout.Column = 1;
    ui.status = uilabel(gl,'Text','INIT'); ui.status.Layout.Row = 2; ui.status.Layout.Column = 2;

    btn = uibutton(gl,'Text','STOP','ButtonPushedFcn',@(~,~)stop_cb());
    btn.Layout.Row = 2; btn.Layout.Column = 3;

    % Row 3 overall lamp
    c = uilabel(gl,'Text','Overall:'); c.Layout.Row = 3; c.Layout.Column = 1;
    ui.l_overall = uilamp(gl); ui.l_overall.Layout.Row = 3; ui.l_overall.Layout.Column = 2;

    % Rows 4..10
    ui.l_pwr  = add_row(4,'r_pwr');
    ui.l_l1   = add_row(5,'r_io_L1');
    ui.l_l2   = add_row(6,'r_io_L2');
    ui.l_iop  = add_row(7,'r_io_pair');
    ui.l_dir  = add_row(8,'r_dir');
    ui.l_trav = add_row(9,'r_trav');
    ui.l_tick = add_row(10,'r_tick');

    % class area (right side)
    ui.class = uitextarea(fig,'Editable','off','Position',[270 20 230 90]);
    ui.class.Value = {'NONE'};
    ui.class.FontName = 'Consolas';
    ui.class.FontSize = 12;

    % init lamps
    set_lamp(ui.l_overall,false);
    set_lamp(ui.l_pwr,false);
    set_lamp(ui.l_l1,false);
    set_lamp(ui.l_l2,false);
    set_lamp(ui.l_iop,false);
    set_lamp(ui.l_dir,false);
    set_lamp(ui.l_trav,false);
    set_lamp(ui.l_tick,false);

    function lamp = add_row(r, name)
        lab = uilabel(gl,'Text',name,'HorizontalAlignment','left');
        lab.Layout.Row = r; lab.Layout.Column = 1;
        lamp = uilamp(gl);
        lamp.Layout.Row = r; lamp.Layout.Column = 2;
    end

    function stop_cb()
        try, fig.UserData.stop = true; catch, end
        try, stop(dq); catch, end
        try, delete(fig); catch, end
    end
end

function set_lamp(lmp, isFault)
    if ~isvalid(lmp), return; end
    if isFault, lmp.Color = [0.85 0.1 0.1];
    else,       lmp.Color = [0.1 0.7 0.1];
    end
end

function set_all_ok(msg)
    ui.status.Text = msg;
    ui.status.FontColor = [0.2 0.2 0.2];
    ui.class.Value = {msg};
    set_lamp(ui.l_overall,false);
    set_lamp(ui.l_pwr,false);
    set_lamp(ui.l_l1,false);
    set_lamp(ui.l_l2,false);
    set_lamp(ui.l_iop,false);
    set_lamp(ui.l_dir,false);
    set_lamp(ui.l_trav,false);
    set_lamp(ui.l_tick,false);
end

function tf = any_col(T, col, mask)
    if isempty(T) || ~ismember(col, string(T.Properties.VariableNames))
        tf = false; return;
    end
    x = T.(col);
    if ~islogical(x), x = logical(x); end
    tf = any(x(mask));
end

function cls = choose_class(alarms, mask)
    cls = "NONE";
    if isempty(alarms) || ~any(mask), return; end
    if ~ismember("class", string(alarms.Properties.VariableNames)), return; end
    prio = ["GLOBAL_POWER","LAMP_OPEN","SENSOR_MISALIGNED","IO_FAULT", ...
            "HBRIDGE_STUCK","MECH_ANOMALY","MULTI_ANOMALY","MIXED_WITH_IO","NONE"];
    recent = alarms.class(mask);
    for k = 1:numel(prio)
        if any(recent == prio(k)), cls = prio(k); return; end
    end
    cls = recent(end);
end

function p = safe_alarm_defaults(p)
    try
        p = conveyor_alarm_defaults(p);
    catch
        if ~isfield(p,'t_ignore_s'), p.t_ignore_s = 5.0; end
        if ~isfield(p,'hold_s'),     p.hold_s     = 0.5; end
    end
end

function v = getfield_with_default(s, f, d)
    if isstruct(s) && isfield(s,f), v = s.(f); else, v = d; end
end

function cfg = monitor_defaults(params)
    cfg = struct();
    cfg.Fs = getfield_with_default(params,'Fs',1000);
    cfg.cb_s = getfield_with_default(params,'cb_s',0.2);
    cfg.ui_s = getfield_with_default(params,'ui_s',0.5);
    cfg.buffer_s = getfield_with_default(params,'buffer_s',30);
    cfg.min_buffer_s = getfield_with_default(params,'min_buffer_s',8);
    cfg.t_ignore_s = getfield_with_default(params,'t_ignore_s',5.0);

    cfg.res_params = struct();
    cfg.res_params.W = getfield_with_default(params,'W',2.0);
    cfg.res_params.S = getfield_with_default(params,'S',0.5);
end

end
