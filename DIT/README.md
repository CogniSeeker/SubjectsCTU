
# Conveyor Diagnosis System (DIT)

MATLAB scripts for calibrating and monitoring a conveyor system using residual-based diagnostics. The workflow supports:

- **Offline testing** on previously recorded datasets
- **Online monitoring** with live recording

## Typical workflow

Run the scripts in this order:

1) **Project initialization (choose dataset for tests / offline use later)**

- Run: `project_init.m`
- Purpose: select and configure a dataset that will be used for subsequent testing.

2) **Calibration + healthy residual check**

- Run: `calib_and_res_check.m`
- Purpose: calibrate the system and verify residuals on a healthy/nominal system.

3) **Run diagnostics (pick one)**

### A) Offline testing (from a recording)

- Ensure you have a recording that was captured using `record_data.m`
- Run: `test_conveyor.m`

### B) Online monitoring (live recording)

- Run: `run_monitoring.m`

## Notes

- `record_data.m` is used to create recordings that can later be replayed by `test_conveyor.m`.
- Core logic is in `DIT/core/` and main functions in `DIT/conveyor_res_helpers/`, and `DIT/conveyor_faults/`. You can find service helper functions in `DIT/helpers/`.

