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

% ignore horizon
T12 = [cal.T12_LR, cal.T12_RL];
T12 = T12(isfinite(T12) & T12 > 0);
if isempty(T12)
    t_ignore = p.t_ignore_s;
else
    t_ignore = max(p.t_ignore_s, 2.0 * max(T12));
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
        st = evalStateAtTime(t, ev, p);
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

function st = evalStateAtTime(t0, ev, p)
isActive = @(te, fe) any(fe & (te > (t0 - p.hold_s)) & (te <= t0));

tickA = isfield(ev,'tick') && isActive(ev.tick.t_s, ev.tick.fire);
travA = isfield(ev,'trav') && isActive(ev.trav.t_s, ev.trav.fire);
dirA  = isfield(ev,'dir')  && isActive(ev.dir.t_s,  ev.dir.fire);

ioPairA = isfield(ev,'io_pair') && isActive(ev.io_pair.t_s, ev.io_pair.fire);
ioL1A   = isfield(ev,'io_L1')   && isActive(ev.io_L1.t_s,   ev.io_L1.fire);
ioL2A   = isfield(ev,'io_L2')   && isActive(ev.io_L2.t_s,   ev.io_L2.fire);
lampA   = ioL1A | ioL2A;

pwrA    = isfield(ev,'pwr') && isActive(ev.pwr.t_s, ev.pwr.fire);

cls = "NONE";
if pwrA
    cls = "GLOBAL_POWER";
elseif lampA
    cls = "LAMP_OPEN";
elseif ioPairA && travA
    cls = "SENSOR_MISALIGNED";
elseif ioPairA && ~dirA && ~tickA && ~travA
    cls = "IO_FAULT";
elseif dirA && ~tickA && ~travA && ~ioPairA && ~lampA
    cls = "HBRIDGE_STUCK";
elseif ~dirA && (tickA || travA) && ~ioPairA && ~lampA
    cls = "MECH_ANOMALY";
elseif (tickA || travA || dirA || ioPairA || lampA) && ~pwrA
    cls = "MIXED";
end

st = makeState(pwrA, lampA, ioPairA, dirA, travA, tickA, cls);
end
