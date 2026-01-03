function monitor_conveyor_realtime(dev, cal, params)
%MONITOR_CONVEYOR_REALTIME Real-time NI DAQ monitor with fault lamps (no replay).

if nargin < 3, params = struct(); end
cfg = monitor_defaults(params);

if nargin < 1
    dev = "";
end

% Build UI first so it can be used even without DAQ toolbox/hardware.
[ui, fig] = build_ui();

% --- NI DAQ (optional) ---
dq = [];
demoMode = false;
try
    dq = daq("ni");
    dq.Rate = cfg.Fs;
catch ME
    demoMode = true;
    ui.status.Text = "DEMO (no DAQ)";
    ui.status.FontColor = [0.2 0.2 0.2];
    ui.class.Value = {ME.message};
end

if ~demoMode
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
end

% --- state ---
buf = timetable();
t_last_ui = -Inf;

% Demo mode state (no DAQ)
t_demo0 = tic;
demoTimer = [];

p_alarm = safe_alarm_defaults(struct());
cfg.res_params = conveyor_defaults(cfg.res_params);

% compute ignore horizon from calibration (fallback to cfg.t_ignore_s)
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
if isempty(T12)
    t_ignore = cfg.t_ignore_s;
else
    t_ignore = max(cfg.t_ignore_s, 1.5 * max(T12));
end
ui.ignore.Text = sprintf('ignore: %.2f s', t_ignore);

if demoMode
    set_all_ok("DEMO (no DAQ)");
    ui.status.Text = "DEMO (no DAQ)";
    ui.status.FontColor = [0.2 0.2 0.2];
    ui.ignore.Text = sprintf('ignore: %.2f s', t_ignore);

    % Periodically update time display so the GUI feels alive.
    demoTimer = timer( ...
        'ExecutionMode','fixedRate', ...
        'Period', cfg.ui_s, ...
        'TimerFcn', @(~,~)demo_tick());
    start(demoTimer);

    while isvalid(fig)
        pause(0.1);
    end

    % cleanup demo timer
    try
        if ~isempty(demoTimer) && isvalid(demoTimer)
            stop(demoTimer);
            delete(demoTimer);
        end
    catch
    end
else
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
end

% =========================
% Callback
% =========================
function onScansAvailable(src, ~)
    if ~isvalid(fig)
        try, stop(src); catch, end
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
        ev = extract_residual_events(res, feat, cal, p_alarm);
        alarms = classify_at_times(ev, p_alarm);
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

    cls = choose_class(alarms, activeMask);
    ui.class.Value = {char(cls)};

    % Show fault classes (kinds of faults) implemented by classify_at_times().
    recent = string.empty(0,1);
    if ~isempty(alarms) && any(activeMask) && ismember("class", string(alarms.Properties.VariableNames))
        recent = string(alarms.class(activeMask));
    end

    flags = struct();
    flags.tick_disconnected          = any(recent == "TICK_DISCONNECTED");
    flags.motor_disconnected         = any(recent == "MOTOR_DISCONNECTED");
    flags.s1_disconnected            = any(recent == "S1_DISCONNECTED");
    flags.s2_disconnected            = any(recent == "S2_DISCONNECTED");
    flags.lamps_disconnected         = any(recent == "LAMPS_DISCONNECTED");
    flags.motor_shifted              = any(recent == "MOTOR_SHIFTED");
    flags.belt_stuck_one_dir         = any(recent == "BELT_STUCK_ONE_DIR");
    flags.belt_abnormal_speed        = any(recent == "BELT_ABNORMAL_SPEED");
    flags.foreign_objects_dir_switch = any(recent == "FOREIGN_OBJECTS_DIR_SWITCH");
    flags.mixed                      = any(recent == "MIXED");

    set_lamp(ui.l_cls_tick_disc,  flags.tick_disconnected);
    set_lamp(ui.l_cls_motor_disc, flags.motor_disconnected);
    set_lamp(ui.l_cls_s1_disc,    flags.s1_disconnected);
    set_lamp(ui.l_cls_s2_disc,    flags.s2_disconnected);
    set_lamp(ui.l_cls_lamps_disc, flags.lamps_disconnected);
    set_lamp(ui.l_cls_motor_shift,flags.motor_shifted);
    set_lamp(ui.l_cls_stuck,      flags.belt_stuck_one_dir);
    set_lamp(ui.l_cls_speed,      flags.belt_abnormal_speed);
    set_lamp(ui.l_cls_foreign,    flags.foreign_objects_dir_switch);
    set_lamp(ui.l_cls_mixed,      flags.mixed);

    isFault = (cls ~= "NONE") || any(struct2array(flags));
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

function demo_tick()
    if ~isvalid(fig)
        return;
    end

    t_now = toc(t_demo0);
    ui.time.Text = sprintf('%.3f', t_now);

    % Keep everything OK in demo mode; GUI is for layout/visibility checks.
    set_all_ok("DEMO (no DAQ)");
    ui.status.Text = "DEMO (no DAQ)";
    ui.status.FontColor = [0.2 0.2 0.2];
    ui.class.Value = {"NONE"};
    drawnow limitrate;
end

% =========================
% UI + helpers
% =========================
function [ui, fig] = build_ui()
    fig = uifigure('Name','Conveyor Monitor (REAL-TIME)','Position',[200 200 620 460]);
    fig.UserData.stop = false;

    gl = uigridlayout(fig, [14 3]);
    gl.RowHeight = {22,22,22,22,22,22,22,22,22,22,22,22,22,'1x'};
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

    % Rows 4..13: show fault classes (kinds of faults).
    ui.l_cls_tick_disc   = add_row(4,  'TICK_DISCONNECTED');
    ui.l_cls_motor_disc  = add_row(5,  'MOTOR_DISCONNECTED');
    ui.l_cls_s1_disc     = add_row(6,  'S1_DISCONNECTED');
    ui.l_cls_s2_disc     = add_row(7,  'S2_DISCONNECTED');
    ui.l_cls_lamps_disc  = add_row(8,  'LAMPS_DISCONNECTED');
    ui.l_cls_motor_shift = add_row(9,  'MOTOR_SHIFTED');
    ui.l_cls_stuck       = add_row(10, 'BELT_STUCK_ONE_DIR');
    ui.l_cls_speed       = add_row(11, 'BELT_ABNORMAL_SPEED');
    ui.l_cls_foreign     = add_row(12, 'FOREIGN_OBJECTS_DIR_SWITCH');
    ui.l_cls_mixed       = add_row(13, 'MIXED');

    % class area (right side)
    ui.class = uitextarea(fig,'Editable','off','Position',[340 20 260 110]);
    ui.class.Value = {'NONE'};
    ui.class.FontName = 'Consolas';
    ui.class.FontSize = 12;

    % init lamps
    set_lamp(ui.l_overall,false);
    set_lamp(ui.l_cls_tick_disc,false);
    set_lamp(ui.l_cls_motor_disc,false);
    set_lamp(ui.l_cls_s1_disc,false);
    set_lamp(ui.l_cls_s2_disc,false);
    set_lamp(ui.l_cls_lamps_disc,false);
    set_lamp(ui.l_cls_motor_shift,false);
    set_lamp(ui.l_cls_stuck,false);
    set_lamp(ui.l_cls_speed,false);
    set_lamp(ui.l_cls_foreign,false);
    set_lamp(ui.l_cls_mixed,false);

    function lamp = add_row(r, name)
        lab = uilabel(gl,'Text',name,'HorizontalAlignment','left');
        lab.Layout.Row = r; lab.Layout.Column = 1;
        lamp = uilamp(gl);
        lamp.Layout.Row = r; lamp.Layout.Column = 2;
    end

    function stop_cb()
        try, fig.UserData.stop = true; catch, end
        try, if ~isempty(dq), stop(dq); end, catch, end
        try
            if ~isempty(demoTimer) && isvalid(demoTimer)
                stop(demoTimer);
                delete(demoTimer);
            end
        catch
        end
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
    set_lamp(ui.l_cls_tick_disc,false);
    set_lamp(ui.l_cls_motor_disc,false);
    set_lamp(ui.l_cls_s1_disc,false);
    set_lamp(ui.l_cls_s2_disc,false);
    set_lamp(ui.l_cls_lamps_disc,false);
    set_lamp(ui.l_cls_motor_shift,false);
    set_lamp(ui.l_cls_stuck,false);
    set_lamp(ui.l_cls_speed,false);
    set_lamp(ui.l_cls_foreign,false);
    set_lamp(ui.l_cls_mixed,false);
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
    prio = ["TICK_DISCONNECTED", ...
            "MOTOR_DISCONNECTED","S1_DISCONNECTED","S2_DISCONNECTED","LAMPS_DISCONNECTED", ...
            "MOTOR_SHIFTED","BELT_STUCK_ONE_DIR","BELT_ABNORMAL_SPEED","FOREIGN_OBJECTS_DIR_SWITCH", ...
            "MIXED","NONE"];
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
