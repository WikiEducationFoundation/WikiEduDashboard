#!/usr/bin/env python3
"""Compare AI detectors on a long-format export from ExportAiDetectionComparison.

    python analyze.py export.csv --out results/ [--threshold 0.9] [--rule max|vendor]
                     [--baseline-provenance pre_llm_term] [--samples NAME ...]
                     [--detectors NAME ...] [--group-by FACTOR ...] [--pair-by FACTOR]

One input row is one (sample unit, detector) result. The script writes PNG charts,
a wide CSV of max scores, a CSV of pairwise disagreements, a challenge-case report,
a list of self-reported false positives worth confirming, and summary.md.

The default positive rule is the production alerting rule, "max window score above
the threshold", applied to every detector so vendors are compared on equal terms.
--rule vendor uses each vendor's own label instead (label == "AI").

Ground truth comes from the export's ground_truth column (human, ai, ai_assisted or
blank for unknown) and provenance says how we know it. The baseline is the set of
human units with --baseline-provenance (pre-ChatGPT terms by default): any positive
there is a false positive. Self-reported units never count as ground truth; they
only feed the candidates list.

Factors (factor_* columns) link units that share a value: --group-by reports rates
per value of a factor (e.g. model, prompt), --pair-by compares human and AI units
that share a value (e.g. topic) as pairs.
"""
import argparse
import itertools
import json
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


AI_LABELS = {"ai", "ai_assisted"}


def load(path, samples, detectors, baseline_provenance, threshold, rule):
    df = pd.read_csv(path, dtype={"ground_truth": "string", "provenance": "string", "notes": "string"})
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
    df["ground_truth"] = df["ground_truth"].fillna("")
    df["provenance"] = df["provenance"].fillna("")
    df["baseline"] = (df["ground_truth"] == "human") & (df["provenance"] == baseline_provenance)
    df["known_ai"] = df["ground_truth"].isin(AI_LABELS)
    # Challenge cases: units with a real label that is not just "written before ChatGPT".
    df["challenge"] = (df["ground_truth"] != "") & ~df["baseline"]
    if rule == "vendor":
        df["positive"] = df["label"] == "AI"
    else:
        df["positive"] = df["max_score"] > threshold
    return df, int(failed.sum())


def factor_columns(df):
    return sorted(c for c in df.columns if c.startswith("factor_"))


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


def chart_distributions(df, out, threshold, baseline_label):
    detectors = detectors_in(df)
    fig, axes = plt.subplots(1, len(detectors), figsize=(4 * len(detectors), 4), sharey=True,
                             facecolor=SURFACE, squeeze=False)
    for ax, detector in zip(axes[0], detectors):
        rows = df[df["check_type"] == detector]
        for is_baseline, color, dash, name in [(True, BASELINE_GRAY, "--", baseline_label),
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


def chart_threshold_sweep(df, out, threshold, baseline_label):
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
                    linestyle="--", linewidth=2, label=f"false positive rate, {baseline_label} (n={len(base)})")
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


def wide_of(df, column):
    """unit_id × detector table of one column; detectors with no values keep an all-blank column."""
    return df.pivot_table(index="unit_id", columns="check_type", values=column, aggfunc="first", dropna=False)


def cell(table, unit_id, column):
    if column not in table.columns:
        return None
    value = table.at[unit_id, column]
    return None if pd.isna(value) else value


def pairwise(df, out_dir, threshold, baseline_label):
    wide = wide_scores(df)
    positives = wide_of(df, "positive")
    units = df.drop_duplicates("unit_id").set_index("unit_id")
    reports = wide_of(df, "report_url")
    rows = []
    disagreements = []
    for a, b in itertools.combinations(detectors_in(df), 2):
        both = wide[[a, b]].dropna()
        if both.empty:
            continue
        # The positive rule was decided in load(); do not re-derive it from the threshold here.
        pos_a = positives.loc[both.index, a].astype(bool)
        pos_b = positives.loc[both.index, b].astype(bool)
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
                                  "url": unit["url"], "report_a": cell(reports, unit_id, a),
                                  "report_b": cell(reports, unit_id, b)})
        chart_scatter(both, units, a, b, threshold, baseline_label,
                      out_dir / f"scatter_{slug(a)}_vs_{slug(b)}.png")
    pd.DataFrame(disagreements).to_csv(out_dir / "disagreements.csv", index=False)
    return pd.DataFrame(rows)


def chart_scatter(both, units, a, b, threshold, baseline_label, out):
    fig, ax = plt.subplots(figsize=(5.5, 5.5), facecolor=SURFACE)
    truth = units.loc[both.index, "baseline"]
    for is_baseline, color, name in [(False, PALETTE[0], "other units"), (True, BASELINE_GRAY, baseline_label)]:
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
    """Positive rate per detector, ground truth and provenance. Units with no label are omitted;
    self-reported units have none, so they never appear here."""
    rows = []
    labeled = df[df["ground_truth"] != ""]
    for detector in detectors_in(labeled):
        d = labeled[labeled["check_type"] == detector]
        for (truth, provenance), subset in d.groupby(["ground_truth", "provenance"], sort=True):
            expectation = "should be negative" if truth == "human" else "should be positive"
            rows.append({"detector": detector, "ground_truth": truth, "provenance": provenance,
                         "expectation": expectation, "units": len(subset),
                         "positive_rate": rate(subset["positive"]),
                         "mean_max_score": round(float(subset["max_score"].mean()), 3)})
    return pd.DataFrame(rows)


def challenge_report(df, threshold):
    """One row per challenge case with every detector's max score and verdict."""
    cases = df[df["challenge"]]
    if cases.empty:
        return pd.DataFrame()
    wide = wide_of(cases, "max_score")
    flagged_wide = wide_of(cases, "positive")
    # Everything below is indexed by unit_id in wide's (sorted) order, so the
    # per-detector columns and the labels stay attached to the same unit.
    units = cases.drop_duplicates("unit_id").set_index("unit_id").loc[wide.index]
    columns = ["ground_truth", "provenance", "notes", "url"] + factor_columns(cases)
    report = units[columns].copy()
    expected = units["ground_truth"].isin(AI_LABELS)
    for detector in detectors_in(cases):
        scores = wide[detector]
        flags = flagged_wide[detector]
        report[detector] = scores.round(4)
        report[f"{detector} verdict"] = [
            verdict(score, flag, exp) for score, flag, exp in zip(scores, flags, expected)
        ]
    return report.reset_index()


def verdict(score, flagged, expected_positive):
    if pd.isna(score):
        return ""
    if bool(flagged) == bool(expected_positive):
        return "correct"
    return "missed" if expected_positive else "false positive"


def self_report_candidates(df, threshold):
    """Disputed alerts (student answered 'false_positive') that a detector still flags: worth a
    human look, since a confirmed case can be promoted to a real challenge case."""
    rows = df[df["provenance"] == "self_report"]
    if rows.empty:
        return pd.DataFrame()
    disputed = rows["metadata"].map(lambda m: metadata_flag(m, "self_reported_false_positive"))
    flagged = rows[disputed & rows["positive"]]
    return flagged[["unit_id", "check_type", "max_score", "campaign_slug", "url", "report_url"]] \
        .sort_values(["unit_id", "check_type"])


def metadata_flag(metadata, key):
    """Read one boolean out of the exported metadata JSON; anything unparsable counts as False."""
    try:
        return bool(json.loads(metadata).get(key, False))
    except (TypeError, ValueError, AttributeError):
        return False


def group_table(df, factor):
    """Positive rate and mean max score per detector for each value of a factor."""
    column = factor if factor.startswith("factor_") else f"factor_{factor}"
    if column not in df.columns:
        return pd.DataFrame()
    rows = []
    with_value = df.dropna(subset=[column])
    for (detector, value), subset in with_value.groupby(["check_type", column], sort=True):
        rows.append({"factor": column.removeprefix("factor_"), "value": value, "detector": detector,
                     "units": len(subset), "positive_rate": rate(subset["positive"]),
                     "mean_max_score": round(float(subset["max_score"].mean()), 3),
                     "known_ai_units": int(subset["known_ai"].sum()),
                     "known_ai_positive_rate": rate(subset[subset["known_ai"]]["positive"])})
    return pd.DataFrame(rows)


def pair_table(df, factor):
    """Human vs AI units sharing a factor value, per detector: the paired score difference shows
    whether a detector separates authorship when topic (or another shared factor) is held fixed."""
    column = factor if factor.startswith("factor_") else f"factor_{factor}"
    if column not in df.columns:
        return pd.DataFrame()
    rows = []
    labeled = df[(df["ground_truth"] != "") & df[column].notna()]
    for (detector, value), subset in labeled.groupby(["check_type", column], sort=True):
        human = subset[subset["ground_truth"] == "human"]
        ai = subset[subset["known_ai"]]
        if human.empty or ai.empty:
            continue
        rows.append({"factor": column.removeprefix("factor_"), "value": value, "detector": detector,
                     "human_units": len(human), "ai_units": len(ai),
                     "human_max": round(float(human["max_score"].mean()), 3),
                     "ai_max": round(float(ai["max_score"].mean()), 3),
                     "difference": round(float(ai["max_score"].mean() - human["max_score"].mean()), 3),
                     "human_flagged": rate(human["positive"]), "ai_flagged": rate(ai["positive"])})
    return pd.DataFrame(rows)


def chart_pairs(pairs, out):
    """Slope chart: one line per shared-factor pair from the human unit's score to the AI unit's,
    one panel per detector."""
    detectors = sorted(pairs["detector"].unique(), key=lambda d: (DETECTOR_ORDER.index(d) if d in DETECTOR_ORDER else 99, d))
    fig, axes = plt.subplots(1, len(detectors), figsize=(3.4 * len(detectors), 4.5), sharey=True,
                             facecolor=SURFACE, squeeze=False)
    for ax, detector in zip(axes[0], detectors):
        rows = pairs[pairs["detector"] == detector]
        for _, row in rows.iterrows():
            ax.plot([0, 1], [row["human_max"], row["ai_max"]], color=color_for(detector), linewidth=2,
                    alpha=0.8, marker="o", markersize=7, markeredgecolor=SURFACE, markeredgewidth=1.5)
        ax.set_xticks([0, 1])
        ax.set_xticklabels(["human", "AI"], color=INK_SOFT)
        ax.set_xlim(-0.3, 1.3)
        ax.set_ylim(0, 1.02)
        ax.set_title(f"{detector} (n={len(rows)} pairs)", loc="left", fontsize=10, color=INK)
        style(ax)
    axes[0][0].set_ylabel("max window score", color=INK_SOFT)
    factor = pairs["factor"].iloc[0]
    fig.suptitle(f"Paired by {factor}: human vs AI units on the same {factor}", x=0.01, ha="left",
                 color=INK, fontsize=12)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


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
    parser.add_argument("--baseline-provenance", default="pre_llm_term",
                        help="provenance whose human units form the false-positive baseline")
    parser.add_argument("--samples", nargs="*")
    parser.add_argument("--detectors", nargs="*")
    parser.add_argument("--group-by", nargs="*", default=[], metavar="FACTOR",
                        help="report rates per value of these factors (e.g. model prompt)")
    parser.add_argument("--pair-by", metavar="FACTOR",
                        help="compare human and AI units sharing this factor (e.g. topic)")
    args = parser.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    df, failed = load(args.export_csv, args.samples, args.detectors, args.baseline_provenance,
                      args.threshold, args.rule)
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
    baseline_label = ("pre-LLM baseline" if args.baseline_provenance == "pre_llm_term"
                      else f"baseline ({args.baseline_provenance})")
    chart_distributions(df, out / "score_distributions.png", args.threshold, baseline_label)
    chart_threshold_sweep(df, out / "threshold_sweep.png", args.threshold, baseline_label)
    pairs = pairwise(df, out, args.threshold, baseline_label)
    wide_scores(df).to_csv(out / "max_scores_wide.csv")

    detectors = detector_table(df)
    truth = ground_truth_table(df)
    challenge = challenge_report(df, args.threshold)
    challenge.to_csv(out / "challenge_cases.csv", index=False)
    candidates = self_report_candidates(df, args.threshold)
    candidates.to_csv(out / "self_report_candidates.csv", index=False)
    groups = pd.concat([group_table(df, f) for f in args.group_by], ignore_index=True) if args.group_by else pd.DataFrame()
    pairs_by_factor = pair_table(df, args.pair_by) if args.pair_by else pd.DataFrame()
    if not pairs_by_factor.empty:
        chart_pairs(pairs_by_factor, out / f"pairs_by_{slug(args.pair_by)}.png")

    summary = [
        "# Detector comparison\n",
        f"Source: `{args.export_csv}`; rule: {args.rule} (threshold {args.threshold}); "
        f"baseline: human units with provenance `{args.baseline_provenance}`; scored rows: {len(df)}; "
        f"failed rows dropped: {failed}.\n",
        "\n## Per detector\n", markdown(detectors),
        "\n## Pairwise agreement\n", markdown(pairs),
        "\n## By ground truth and provenance\n", markdown(truth),
        "\n## Challenge cases\n",
        f"{len(challenge)} labeled units beyond the baseline; per-case scores and verdicts in challenge_cases.csv.\n",
        "\n## Self-reported false positives still flagged\n",
        f"{len(candidates)} rows in self_report_candidates.csv (self-reports are not ground truth; "
        "these are candidates for a human to confirm).\n",
    ]
    if not groups.empty:
        summary += ["\n## By factor\n", markdown(groups)]
    if not pairs_by_factor.empty:
        summary += [f"\n## Paired by {args.pair_by}\n", markdown(pairs_by_factor)]
    summary.append(
        "\nCharts: positive_rate_by_term.png, mean_max_score_by_term.png, mean_window_score_by_term.png, "
        "score_distributions.png, threshold_sweep.png, scatter_*.png, pairs_by_*.png. "
        "Data: max_scores_wide.csv, disagreements.csv, challenge_cases.csv, self_report_candidates.csv.\n")
    (out / "summary.md").write_text("".join(summary))
    print("\n".join(str(p) for p in sorted(out.iterdir())))


if __name__ == "__main__":
    main()
