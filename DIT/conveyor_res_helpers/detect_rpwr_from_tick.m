function r_pwr = detect_rpwr_from_tick(win_centers, mv_mean, f_tick, params)
%DETECT_RPWR_FROM_TICK Binary power residual: motor_on but tick ~ 0.

if nargin < 4 || isempty(params), params = struct(); end
if ~isfield(params,'mvOnEps'),      params.mvOnEps = 0.02; end
if ~isfield(params,'pwrMinTickHz'), params.pwrMinTickHz = 0.2; end % "tick disappeared" threshold
if ~isfield(params,'pwrBlank_s'),   params.pwrBlank_s = 0.5; end   % optional; handle NaNs

motor_on = mv_mean > params.mvOnEps;

r_pwr = false(size(win_centers));
ok = isfinite(f_tick) & isfinite(mv_mean);

% power symptom: motor seems on, but tick very low/zero
r_pwr(ok) = motor_on(ok) & (f_tick(ok) < params.pwrMinTickHz);
end
