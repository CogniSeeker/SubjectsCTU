% monitor_conveyor_live.m
% Pseudo-real-time monitor (OK=green / FAULT=red) while replaying TT.

%% ---- Inputs ----
TT = data;     % or load_first_timetable("data/data_150s.mat");
cal = cal150;

params = struct();
params.W = 2.0;
params.S = 0.5;

[res, feat] = calc_residuals(TT, cal, params);

p = conveyor_alarm_defaults(struct());
ev = extract_residual_events(res, feat, cal, p);
alarms = classify_at_times(ev, p);

% ignore horizon
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
if isempty(T12)
    t_ignore = p.t_ignore_s;
else
    t_ignore = max(p.t_ignore_s, 1.5 * max(T12));
end

rt    = TT.Properties.RowTimes;
t_end = seconds(rt(end) - rt(1));


dt = 0.05;        % UI refresh [s]
simSpeed = 1.0;   % 1.0 real-time

%% ---- GUI ----
fig = uifigure('Name','Conveyor Monitor (Replay)', 'Position',[100 100 560 360]);
fig.UserData.stop = false;

gl = uigridlayout(fig, [8 3]);
gl.RowHeight = {28,28,28,28,28,28,28,'1x'};
gl.ColumnWidth = {220,'1x',120};

% Row 1
labT = uilabel(gl,'Text','Time [s]:','HorizontalAlignment','left');
labT.Layout.Row = 1; labT.Layout.Column = 1;

lblTime = uilabel(gl,'Text','0.000','HorizontalAlignment','left');
lblTime.Layout.Row = 1; lblTime.Layout.Column = 2;

btnStop = uibutton(gl,'Text','STOP','ButtonPushedFcn',@(src,evt)setStop(fig));
btnStop.Layout.Row = 1; btnStop.Layout.Column = 3;

% Rows 2..7
powerRow = mkRow(gl, 'Power (r\_pwr)', 2);
lampRow  = mkRow(gl, 'Lamp (r\_io\_L1/L2)', 3);
ioRow    = mkRow(gl, 'IO pair (r\_io\_pair)', 4);
dirRow   = mkRow(gl, 'Direction (r\_dir)', 5);
travRow  = mkRow(gl, 'Travel (r\_trav)', 6);
tickRow  = mkRow(gl, 'Tick (r\_tick)', 7);

% Bottom status area
ax = uiaxes(gl);
ax.Layout.Row = 8; ax.Layout.Column = [1 3];
ax.XLim = [0 1]; ax.YLim = [0 1];
ax.XTick = []; ax.YTick = [];
box(ax,'on');

txt  = text(ax, 0.02, 0.65, "OK", 'FontSize',16, 'FontWeight','bold', 'Interpreter','none');
txt2 = text(ax, 0.02, 0.25, "class: NONE", 'FontSize',12, 'Interpreter','none');

%% ---- Replay loop ----
t0_wall = tic;

while isvalid(fig) && ~fig.UserData.stop
    t = min(t_end, toc(t0_wall) * simSpeed);

    if t < t_ignore
        st = makeState(false,false,false,false,false,false,"STARTUP_IGNORE");
        overall = "OK";
    else
        st = evalStateAtTime(t, alarms, p);
        overall = "OK";
        if st.pwr || st.class ~= "NONE"
            overall = "FAULT";
        end
    end

    lblTime.Text = sprintf('%.3f', t);

    setLamp(powerRow, st.pwr);
    setLamp(lampRow,  st.lamp);
    setLamp(ioRow,    st.io_pair);
    setLamp(dirRow,   st.dir);
    setLamp(travRow,  st.trav);
    setLamp(tickRow,  st.tick);

    if overall == "FAULT"
        txt.String = "FAULT";
        txt.Color = [1 1 1];
        ax.Color = [0.85 0.15 0.15];
    else
        txt.String = "OK";
        txt.Color = [0 0 0];
        ax.Color = [0.30 0.85 0.30];
    end
    txt2.String = "class: " + st.class;

    drawnow limitrate;

    if t >= t_end
        break;
    end
    pause(dt / max(simSpeed, eps));
end

%% =========================
% Local helper functions
% =========================
function setStop(fig)
fig.UserData.stop = true;
end

function row = mkRow(gl, name, r)
lab = uilabel(gl,'Text',name,'HorizontalAlignment','left');
lab.Layout.Row = r; lab.Layout.Column = 1;

lamp = uilabel(gl,'Text','OK','HorizontalAlignment','center','FontWeight','bold', ...
    'BackgroundColor',[0.30 0.85 0.30]);
lamp.Layout.Row = r; lamp.Layout.Column = 3;

row.lamp = lamp;
end

function setLamp(row, isFault)
if isFault
    row.lamp.Text = 'FAULT';
    row.lamp.BackgroundColor = [0.85 0.15 0.15];
    row.lamp.FontColor = [1 1 1];
else
    row.lamp.Text = 'OK';
    row.lamp.BackgroundColor = [0.30 0.85 0.30];
    row.lamp.FontColor = [0 0 0];
end
end

function st = makeState(pwr,lamp,io_pair,dir,trav,tick,cls)
st = struct('pwr',logical(pwr), 'lamp',logical(lamp), 'io_pair',logical(io_pair), ...
            'dir',logical(dir), 'trav',logical(trav), 'tick',logical(tick), ...
            'class',string(cls));
end

function st = evalStateAtTime(t0, alarms, p)

hold_s = getfield_with_default(p, 'hold_s', 0.5);
t1 = t0 - hold_s;
mask = (alarms.t_s > t1) & (alarms.t_s <= t0);

tickA = any_col(alarms, "tick", mask);
travA = any_col(alarms, "trav", mask);
dirA  = any_col(alarms, "dir",  mask);

% Legacy UI rows (pwr/lamp/io_pair) are kept for display only.
% With the new classifier, they may be absent from alarms -> shown as OK.
pwrA    = any_col(alarms, "pwr", mask);
ioPairA = any_col(alarms, "io_pair", mask);
lampA   = any_col(alarms, "io_L1", mask) | any_col(alarms, "io_L2", mask);

cls = choose_class(alarms, mask);
st = makeState(pwrA, lampA, ioPairA, dirA, travA, tickA, cls);
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

function v = getfield_with_default(s, f, d)
    if isstruct(s) && isfield(s,f), v = s.(f); else, v = d; end
end
