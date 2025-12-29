function params = conveyor_defaults(params)
%CONVEYOR_DEFAULTS Fill missing params with defaults (no logic change).

if nargin < 1 || isempty(params)
    params = struct();
end

if ~isfield(params,'W'),            params.W = 0.5; end % [s]
if ~isfield(params,'S'),            params.S = 0.25; end % [s]
if ~isfield(params,'mvEps'),        params.mvEps = 0.01; end
if ~isfield(params,'dirEps'),       params.dirEps = 0.01; end
if ~isfield(params,'tauSearchMax'), params.tauSearchMax = 1.0; end
if ~isfield(params,'minFlipGap'), params.minFlipGap = 1.0; end % [s]
if ~isfield(params,'minSensorGap'), params.minSensorGap = 0.1; end   % [s]
if ~isfield(params,'revBlank'),     params.revBlank     = 0.5; end   % [s]
if ~isfield(params,'T12_min'),      params.T12_min      = 2; end   % [s]
if ~isfield(params,'T12_max'),      params.T12_max      = 8.0; end  % [s]
if ~isfield(params,'tickMinGap'),   params.tickMinGap   = 0.05; end % [s]
if ~isfield(params,'thr_s1'),   params.thr_s1   = 2; end % [s]
if ~isfield(params,'thr_s2'),   params.thr_s2   = 3.8; end % [s]
if ~isfield(params,'thr_tick'),   params.thr_tick   = 2.5; end % [s]

if ~isfield(params,'mvOnEps'),   params.mvOnEps   = 0.02; end % [s]
if ~isfield(params,'pwrMinTickHz'),   params.pwrMinTickHz   = 0.2; end % [1/s]

% --- Lamp / IO monitoring (v_i5) ---
if ~isfield(params,'lampVarName'),     params.lampVarName = 'v_i5'; end

% L1 disconnected -> v_i5 ~ 0 V (but short 0 V dips may occur)
if ~isfield(params,'lampLowV'),        params.lampLowV = 0.4; end        % [V]
if ~isfield(params,'lampLowMinDur'),   params.lampLowMinDur = 0.1; end   % [s] ignore

% L2 disconnected -> v_i5 drops from ~1.53 V to ~1.52 V
% We detect sustained drop vs baseline median (cal.lamp_mu)
if ~isfield(params,'lampL2DropV'),     params.lampL2DropV = 0.01; end    % [V] ~8 mV
if ~isfield(params,'lampL2MinDur'),    params.lampL2MinDur = 0.1; end    % [s]

% Debounce spacing between repeated lamp alarms
if ~isfield(params,'lampEventMinGap'), params.lampEventMinGap = 0.2; end % [s]

% Pair-mismatch IO residual (sensor-based)
if ~isfield(params,'ioMargin_s'),      params.ioMargin_s = 0.6; end      % [s]

% ---- Generic "disconnected" detection (near-0V and low variance) ----
% These residuals are intended to detect wiring/disconnect cases where the
% channel collapses to ~0 V for a sustained period.
if ~isfield(params,'discStdV'),        params.discStdV        = 0.05; end % [V]

% Tick channel disconnected (v_i3)
if ~isfield(params,'tickDiscLowV'),    params.tickDiscLowV    = 0.10; end % [V]

% Motor terminal disconnected (v_i4)
if ~isfield(params,'motorDiscLowV'),   params.motorDiscLowV   = 0.10; end % [V]

% Lamp channel disconnected (v_i5) -> reuse lampLowV as low threshold
% (lampLowV already defaults to ~0.4 V)

% ---- Sensor disconnect / stuck detection (new) ----
if ~isfield(params,'sensorMissingMargin_s'), params.sensorMissingMargin_s = 1.0; end
if ~isfield(params,'sensorStuckStdV'),       params.sensorStuckStdV       = 0.5; end
if ~isfield(params,'sensorStuckLowV'),       params.sensorStuckLowV       = 0.10; end
% NOTE: for active-low sensors, idle-high is normal; stuck-high is detected via missing events.
% Kept for backward compatibility.
if ~isfield(params,'sensorStuckHighV'),      params.sensorStuckHighV      = 4.90; end


end
