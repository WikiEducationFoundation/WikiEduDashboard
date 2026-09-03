#!/usr/bin/env python3
"""Compare AI detectors on a long-format export from ExportAiDetectionComparison.

    python analyze.py export.csv --out results/ [--threshold 0.9] [--rule max|vendor]
                     [--baseline human_pre_llm] [--samples NAME ...] [--detectors NAME ...]

One input row is one (sample unit, detector) result. The script writes PNG charts,
a wide CSV of max scores, a CSV of pairwise disagreements, and summary.md.

The default positive rule is the production alerting rule, "max window score above
the threshold", applied to every detector so vendors are compared on equal terms.
--rule vendor uses each vendor's own label instead (label == "AI").

Ground truth labels come from the export: units labeled with --baseline are treated
as human-written, so any positive on them is a false positive.
"""
import argparse
import itertools
import math
import pathlib
import re
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402

# Categorical palette and fixed slot order (see the dataviz reference palette):
# a detector keeps its hue regardless of which others are on the chart.
PALETTE = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#4a3aa7", "#e34948"]
DETECTOR_ORDER = [
    "Pangram 3",
    "Pangram 4",
    "Originality Lite 1.0.2",
    "Originality Turbo",
    "Originality Academic",
    "Originality AI Allowance 15",
    "Originality AI Allowance 40",
]
INK = "#0b0b0b"
INK_SOFT = "#52514e"
GRID = "#e6e5e1"
SURFACE = "#fcfcfb"
BASELINE_GRAY = "#8a8985"
SEASONS = {"spring": 0, "summer": 1, "fall": 2}


def color_for(detector):
    if detector in DETECTOR_ORDER:
        return PALETTE[DETECTOR_ORDER.index(detector)]
    return PALETTE[-1]  # one spare slot; more than that should be folded or faceted


def term_parts(slug):
    match = re.fullmatch(r"(spring|summer|fall)_(\d{4})", str(slug))
    if not match:
        return None, None
    season, year = match.groups()
    return (int(year), SEASONS[season]), f"{season.capitalize()} {year}"


def load(path, samples, detectors, baseline, threshold, rule):
    df = pd.read_csv(path)
    if samples:
        df = df[df["sample_name"].isin(samples)]
    if detectors:
        df = df[df["check_type"].isin(detectors)]
    failed = df["error"].notna() & df["max_score"].isna()
    df = df[~failed].copy()
    for column in ["max_score", "mean_window_score", "document_score", "word_count"]:
        df[column] = pd.to_numeric(df[column], errors="coerce")
    df = df.dropna(subset=["max_score"])
    keys_labels = df["campaign_slug"].map(term_parts)
    df["term_key"] = keys_labels.map(lambda pair: pair[0])
    df["term"] = keys_labels.map(lambda pair: pair[1])
    df["baseline"] = df["ground_truth"] == baseline
    if rule == "vendor":
        df["positive"] = df["label"] == "AI"
    else:
        df["positive"] = df["max_score"] > threshold
    return df, int(failed.sum())


def detectors_in(df):
    present = df["check_type"].unique().tolist()
    return sorted(present, key=lambda d: (DETECTOR_ORDER.index(d) if d in DETECTOR_ORDER else 99, d))


def style(ax, percent=False):
    ax.set_facecolor(SURFACE)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        ax.spines[side].set_color(GRID)
    ax.tick_params(colors=INK_SOFT, labelsize=9)
    ax.yaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    if percent:
        ax.yaxis.set_major_formatter(matplotlib.ticker.PercentFormatter(1.0, decimals=0))


def end_labels(ax, x, labels, min_gap):
    """Direct labels at the right end of each line, nudged apart so they never overlap."""
    placed = []
    for y, text, color in sorted(labels):
        label_y = y if not placed else max(y, placed[-1] + min_gap)
        placed.append(label_y)
        ax.annotate(text, (x, y), xytext=(8, (label_y - y) / min_gap * 11), textcoords="offset points",
                    va="center", fontsize=9, color=INK)
        ax.plot([x], [y], marker="o", markersize=8, color=color)


def by_term(df, value_column, aggregate):
    with_terms = df.dropna(subset=["term_key"])
    if with_terms.empty:
        return None
    table = with_terms.groupby(["term_key", "term", "check_type"])[value_column].agg(aggregate)
    table = table.reset_index().sort_values("term_key")
    return table


def chart_lines_by_term(table, value_column, title, ylabel, out, percent):
    terms = table.drop_duplicates("term_key").sort_values("term_key")
    positions = {key: i for i, key in enumerate(terms["term_key"])}
    fig, ax = plt.subplots(figsize=(10, 5.5), facecolor=SURFACE)
    top = 1 if percent else max(1, table[value_column].max() * 1.05)
    labels = []
    for detector in detectors_in(table):
        rows = table[table["check_type"] == detector]
        xs = [positions[key] for key in rows["term_key"]]
        ax.plot(xs, rows[value_column], color=color_for(detector), linewidth=2, label=detector,
                marker="o", markersize=8, markeredgecolor=SURFACE, markeredgewidth=2)
        labels.append((rows[value_column].iloc[-1], detector, color_for(detector)))
    end_labels(ax, max(positions.values()), labels, min_gap=top * 0.035)
    ax.set_xticks(list(positions.values()))
    ax.set_xticklabels(terms["term"], rotation=30, ha="right")
    ax.set_ylim(0, top)
    ax.set_xlim(-0.3, max(positions.values()) + 0.5)
    ax.set_title(title, loc="left", color=INK, fontsize=12)
    ax.set_ylabel(ylabel, color=INK_SOFT)
    ax.legend(frameon=False, fontsize=9, labelcolor=INK)
    style(ax, percent=percent)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


def ecdf(values):
    values = sorted(values)
    return values, [(i + 1) / len(values) for i in range(len(values))]


def chart_distributions(df, out, threshold):
    detectors = detectors_in(df)
    fig, axes = plt.subplots(1, len(detectors), figsize=(4 * len(detectors), 4), sharey=True,
                             facecolor=SURFACE, squeeze=False)
    for ax, detector in zip(axes[0], detectors):
        rows = df[df["check_type"] == detector]
        for is_baseline, color, dash, name in [(True, BASELINE_GRAY, "--", "pre-LLM baseline"),
                                                (False, color_for(detector), "-", "other units")]:
            subset = rows[rows["baseline"] == is_baseline]["max_score"]
            if subset.empty:
                continue
            xs, ys = ecdf(subset)
            ax.step(xs, ys, where="post", color=color, linestyle=dash, linewidth=2,
                    label=f"{name} (n={len(subset)})")
        ax.axvline(threshold, color=INK_SOFT, linewidth=1, linestyle=":")
        ax.set_title(detector, loc="left", fontsize=10, color=INK)
        ax.set_xlabel("max window score", color=INK_SOFT)
        ax.set_xlim(0, 1)
        ax.legend(frameon=False, fontsize=8, loc="lower right", labelcolor=INK)
        style(ax, percent=True)
    axes[0][0].set_ylabel("share of units at or below score", color=INK_SOFT)
    fig.suptitle("Score distributions (ECDF)", x=0.01, ha="left", color=INK, fontsize=12)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


def chart_threshold_sweep(df, out, threshold):
    detectors = detectors_in(df)
    thresholds = [i / 100 for i in range(0, 100)]
    fig, axes = plt.subplots(1, len(detectors), figsize=(4 * len(detectors), 4), sharey=True,
                             facecolor=SURFACE, squeeze=False)
    for ax, detector in zip(axes[0], detectors):
        rows = df[df["check_type"] == detector]
        base = rows[rows["baseline"]]["max_score"]
        rest = rows[~rows["baseline"]]["max_score"]
        if not base.empty:
            ax.plot(thresholds, [(base > t).mean() for t in thresholds], color=BASELINE_GRAY,
                    linestyle="--", linewidth=2, label=f"false positive rate, baseline (n={len(base)})")
        if not rest.empty:
            ax.plot(thresholds, [(rest > t).mean() for t in thresholds], color=color_for(detector),
                    linewidth=2, label=f"positive rate, other units (n={len(rest)})")
        ax.axvline(threshold, color=INK_SOFT, linewidth=1, linestyle=":")
        ax.set_title(detector, loc="left", fontsize=10, color=INK)
        ax.set_xlabel("threshold on max window score", color=INK_SOFT)
        ax.set_xlim(0, 1)
        ax.legend(frameon=False, fontsize=8, loc="upper right", labelcolor=INK)
        style(ax, percent=True)
    axes[0][0].set_ylabel("share of units above threshold", color=INK_SOFT)
    fig.suptitle("Threshold sweep", x=0.01, ha="left", color=INK, fontsize=12)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


def wide_scores(df):
    return df.pivot_table(index="unit_id", columns="check_type", values="max_score", aggfunc="first")


def pairwise(df, out_dir, threshold):
    wide = wide_scores(df)
    units = df.drop_duplicates("unit_id").set_index("unit_id")
    reports = df.pivot_table(index="unit_id", columns="check_type", values="report_url", aggfunc="first")
    rows = []
    disagreements = []
    for a, b in itertools.combinations(detectors_in(df), 2):
        both = wide[[a, b]].dropna()
        if both.empty:
            continue
        pos_a, pos_b = both[a] > threshold, both[b] > threshold
        rows.append({"detector_a": a, "detector_b": b, "units": len(both),
                     "both_positive": int((pos_a & pos_b).sum()),
                     "only_a": int((pos_a & ~pos_b).sum()), "only_b": int((~pos_a & pos_b).sum()),
                     "both_negative": int((~pos_a & ~pos_b).sum()),
                     "agreement": round(float((pos_a == pos_b).mean()), 3)})
        for unit_id in both.index[pos_a != pos_b]:
            unit = units.loc[unit_id]
            disagreements.append({"unit_id": unit_id, "detector_a": a, "detector_b": b,
                                  "score_a": both.at[unit_id, a], "score_b": both.at[unit_id, b],
                                  "ground_truth": unit["ground_truth"], "campaign_slug": unit["campaign_slug"],
                                  "url": unit["url"], "report_a": reports.at[unit_id, a],
                                  "report_b": reports.at[unit_id, b]})
        chart_scatter(both, units, a, b, threshold, out_dir / f"scatter_{slug(a)}_vs_{slug(b)}.png")
    pd.DataFrame(disagreements).to_csv(out_dir / "disagreements.csv", index=False)
    return pd.DataFrame(rows)


def chart_scatter(both, units, a, b, threshold, out):
    fig, ax = plt.subplots(figsize=(5.5, 5.5), facecolor=SURFACE)
    truth = units.loc[both.index, "baseline"]
    for is_baseline, color, name in [(False, PALETTE[0], "other units"), (True, BASELINE_GRAY, "pre-LLM baseline")]:
        subset = both[truth == is_baseline]
        if subset.empty:
            continue
        ax.scatter(subset[a], subset[b], s=36, color=color, alpha=0.7, edgecolors=SURFACE,
                   linewidths=1, label=f"{name} (n={len(subset)})")
    for line in (ax.axhline, ax.axvline):
        line(threshold, color=INK_SOFT, linewidth=1, linestyle=":")
    ax.set_xlim(-0.02, 1.02)
    ax.set_ylim(-0.02, 1.02)
    ax.set_xlabel(f"{a} max window score", color=INK_SOFT)
    ax.set_ylabel(f"{b} max window score", color=INK_SOFT)
    ax.set_title(f"{a} vs {b}", loc="left", color=INK, fontsize=12)
    ax.legend(frameon=False, fontsize=9, labelcolor=INK)
    style(ax)
    ax.xaxis.grid(True, color=GRID, linewidth=0.8)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def detector_table(df):
    rows = []
    for detector in detectors_in(df):
        d = df[df["check_type"] == detector]
        base, rest = d[d["baseline"]], d[~d["baseline"]]
        rows.append({"detector": detector, "units": len(d),
                     "baseline_units": len(base),
                     "false_positive_rate": rate(base["positive"]),
                     "other_units": len(rest), "positive_rate": rate(rest["positive"]),
                     "mean_max_score": round(float(d["max_score"].mean()), 3),
                     "mean_window_score": round(float(d["mean_window_score"].mean()), 3)
                     if d["mean_window_score"].notna().any() else None})
    return pd.DataFrame(rows)


def ground_truth_table(df):
    negatives = {"human_pre_llm", "self_reported_no_ai"}
    positives = {"self_reported_ai", "experiment_ai"}
    rows = []
    for detector in detectors_in(df):
        d = df[df["check_type"] == detector]
        for truth in sorted(d["ground_truth"].dropna().unique()):
            subset = d[d["ground_truth"] == truth]
            kind = "should be negative" if truth in negatives else "should be positive" if truth in positives else "unlabeled"
            rows.append({"detector": detector, "ground_truth": truth, "expectation": kind,
                         "units": len(subset), "positive_rate": rate(subset["positive"])})
    return pd.DataFrame(rows)


def rate(series):
    return None if series.empty else round(float(series.mean()), 3)


def markdown(table):
    if table is None or table.empty:
        return "_none_\n"
    return table.to_markdown(index=False, floatfmt=".3f") + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("export_csv")
    parser.add_argument("--out", default="results")
    parser.add_argument("--threshold", type=float, default=0.9)
    parser.add_argument("--rule", choices=["max", "vendor"], default="max")
    parser.add_argument("--baseline", default="human_pre_llm")
    parser.add_argument("--samples", nargs="*")
    parser.add_argument("--detectors", nargs="*")
    args = parser.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    df, failed = load(args.export_csv, args.samples, args.detectors, args.baseline, args.threshold, args.rule)
    if df.empty:
        sys.exit("no scored rows after filtering")

    rate_table = by_term(df, "positive", "mean")
    if rate_table is not None:
        rule = f"max window score > {args.threshold}" if args.rule == "max" else "vendor label"
        chart_lines_by_term(rate_table, "positive", f"Positive rate by term ({rule})",
                            "share of units flagged", out / "positive_rate_by_term.png", percent=True)
        chart_lines_by_term(by_term(df, "max_score", "mean"), "max_score", "Mean max window score by term",
                            "mean of per-unit max score", out / "mean_max_score_by_term.png", percent=False)
        if df["mean_window_score"].notna().any():
            chart_lines_by_term(by_term(df.dropna(subset=["mean_window_score"]), "mean_window_score", "mean"),
                                "mean_window_score", "Mean window score by term",
                                "mean of per-unit mean window score", out / "mean_window_score_by_term.png",
                                percent=False)
    chart_distributions(df, out / "score_distributions.png", args.threshold)
    chart_threshold_sweep(df, out / "threshold_sweep.png", args.threshold)
    pairs = pairwise(df, out, args.threshold)
    wide_scores(df).to_csv(out / "max_scores_wide.csv")

    detectors = detector_table(df)
    truth = ground_truth_table(df)
    summary = [
        "# Detector comparison\n",
        f"Source: `{args.export_csv}`; rule: {args.rule} (threshold {args.threshold}); "
        f"baseline label: `{args.baseline}`; scored rows: {len(df)}; failed rows dropped: {failed}.\n",
        "\n## Per detector\n", markdown(detectors),
        "\n## Pairwise agreement\n", markdown(pairs),
        "\n## By ground truth\n", markdown(truth),
        "\nCharts: positive_rate_by_term.png, mean_max_score_by_term.png, mean_window_score_by_term.png, "
        "score_distributions.png, threshold_sweep.png, scatter_*.png. Data: max_scores_wide.csv, disagreements.csv.\n",
    ]
    (out / "summary.md").write_text("".join(summary))
    print("\n".join(str(p) for p in sorted(out.iterdir())))


if __name__ == "__main__":
    main()
