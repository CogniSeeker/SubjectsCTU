"""Generate a scikit-learn confusion matrix in the same label order as the report.

Label order is taken from Table tab:fault_matrix (columns):
  Motor disc., S1 disc., S2 disc., Lamps disc., Tick disc., Belt speed,
  Belt stuck (dir.), Foreign object, Motor shift.

Counts (provided):
- Correct: S1=2, S2=2, Tick=2, Lamps=2, Motor off=1, Motor shift=1,
  Foreign object=1, Belt speed=1
- Incorrect: predicted "Belt speed" but true "Motor shift" (one case)

Outputs:
- Prints the label order and the integer confusion matrix.
- Saves a plot (PDF + PNG) to DIT/report/materials by default.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix


LABELS = [
    "Motor disconnected",
    "S1 disconnected",
    "S2 disconnected",
    "Lamps disconnected",
    "Tick disconnected",
    "Belt speed",
    "Belt stuck (dir.)",
    "Foreign object",
    "Motor shift",
]


def build_counts_matrix() -> np.ndarray:
    """Build confusion counts in the required label order.

    Rows = true class, columns = predicted class.
    """

    n = len(LABELS)
    counts = np.zeros((n, n), dtype=int)

    idx = {name: i for i, name in enumerate(LABELS)}

    # Correct predictions.
    counts[idx["Motor disconnected"], idx["Motor disconnected"]] = 2
    counts[idx["S1 disconnected"], idx["S1 disconnected"]] = 2
    counts[idx["S2 disconnected"], idx["S2 disconnected"]] = 2
    counts[idx["Lamps disconnected"], idx["Lamps disconnected"]] = 2
    counts[idx["Tick disconnected"], idx["Tick disconnected"]] = 2
    counts[idx["Belt speed"], idx["Belt speed"]] = 1
    counts[idx["Belt stuck (dir.)"], idx["Belt stuck (dir.)"]] = 1
    counts[idx["Foreign object"], idx["Foreign object"]] = 1
    counts[idx["Motor shift"], idx["Motor shift"]] = 1

    # Incorrect predictions.
    # true: Motor shift, predicted: Belt speed
    counts[idx["Motor shift"], idx["Belt speed"]] += 1

    return counts


def expand_labels_from_counts(counts: np.ndarray, labels: list[str]) -> tuple[list[str], list[str]]:
    """Convert a count matrix into y_true/y_pred label lists."""

    y_true: list[str] = []
    y_pred: list[str] = []

    for true_i, true_label in enumerate(labels):
        for pred_i, pred_label in enumerate(labels):
            c = int(counts[true_i, pred_i])
            if c <= 0:
                continue
            y_true.extend([true_label] * c)
            y_pred.extend([pred_label] * c)

    return y_true, y_pred


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "report" / "materials",
        help="Output directory for confusion matrix plot (default: DIT/report/materials)",
    )
    parser.add_argument(
        "--basename",
        type=str,
        default="confusion_matrix",
        help="Base name (without extension) for saved plot files",
    )
    args = parser.parse_args()

    counts = build_counts_matrix()
    y_true, y_pred = expand_labels_from_counts(counts, LABELS)

    cm = confusion_matrix(y_true, y_pred, labels=LABELS)

    print("Label order:")
    for i, name in enumerate(LABELS, start=1):
        print(f"{i:2d}. {name}")

    print("\nConfusion matrix (rows=true, cols=pred):")
    print(cm)

    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=LABELS)

    fig = disp.plot(
        include_values=True,
        cmap="Blues",
        xticks_rotation=45,
        values_format="d",
        colorbar=False,
    ).figure_

    fig.set_size_inches(9.5, 7.0)
    fig.tight_layout()

    out_dir: Path = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    pdf_path = out_dir / f"{args.basename}.pdf"
    png_path = out_dir / f"{args.basename}.png"

    fig.savefig(pdf_path, bbox_inches="tight")
    fig.savefig(png_path, dpi=200, bbox_inches="tight")

    print(f"\nSaved: {pdf_path}")
    print(f"Saved: {png_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
