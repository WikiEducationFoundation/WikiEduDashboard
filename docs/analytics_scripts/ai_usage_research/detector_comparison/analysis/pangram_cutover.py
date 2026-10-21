#!/usr/bin/env python3
"""Detector cutover analysis on a long-format export from ExportAiDetectionComparison.

    python pangram_cutover.py export.csv --out results/cutover [--threshold 0.9]
                              [--old "Pangram 3"] [--new "Pangram 4"]
                              [--recent-sample recent_2026_09]
                              [--population low=12558 mid=770 high=1305]
                              [--checks-per-month 600]

Companion to analyze.py for the questions that decide whether production alerting can
move from one detector (--old) to another (--new). analyze.py compares detectors on
equal terms; this script asks what changes for the alert pipeline:

1. Positive rate per production score band on the recent sample, reweighted by the
   production population of each band (--population, counts of production checks) into
   a projected alert rate for each detector, and per month with --checks-per-month.
2. Reproducibility of the old detector: its fresh score against the production score
   stored in the unit's metadata (source_max_ai_likelihood). Run-to-run noise bounds how
   much old-vs-new difference is meaningful.
3. Transitions at the threshold (both positive, old only, new only, neither) per sample
   and old model version.
4. Signals only the new detector reports: humanized windows, and the score distribution
   of each document label (whether "Mixed" stays under the threshold).
5. Window geometry: words per window for each detector.
6. Baseline false-positive rate per detector and model version.

Positive means max window score above --threshold, the production rule. Failed rows
and rows without a score are dropped as in analyze.py. Writes CSVs, PNG charts and
cutover_summary.md to --out.
"""
import argparse
import json
import pathlib
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import analyze as az  # noqa: E402

BANDS = ["low", "mid", "high"]
BAND_LABELS = {"low": "low (< 0.5)", "mid": "mid (0.5–0.9)", "high": "high (≥ 0.9)"}
# Production Pangram 3 checks since 2026-01-01 by band, from the 2026-09-04 preflight.
DEFAULT_POPULATION = {"low": 12558, "mid": 770, "high": 1305}
DEFAULT_POPULATION_DATE = "2026-09-04"
# Document labels take the palette slots after the detectors so a label keeps its hue
# across charts. The pink slot is under 3:1 on the light surface, so label lines are
# always direct-labeled and every label chart has a table beside it in the summary.
LABEL_COLORS = {"AI": az.PALETTE[4], "Mixed": az.PALETTE[5], "Human": az.PALETTE[6]}
REFERENCE_WORDS_PER_WINDOW = 400  # the segment size the alert emails describe


def parse_metadata(value):
    if not isinstance(value, str) or not value.strip():
        return {}
    try:
        parsed = json.loads(value)
    except json.JSONDecodeError:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def parse_population(items):
    """Band counts and their shares, plus which bands came from --population.

    Partial input is merged over DEFAULT_POPULATION, so a fresh count for one band
    is combined with preflight counts for the others. The headline output of this
    script is a rate reweighted by these shares, so the provenance of each band
    travels with them and is printed in the summary.
    """
    population = dict(DEFAULT_POPULATION)
    given = set()
    for item in items or []:
        band, _, count = item.partition("=")
        if band not in BANDS or not count.isdigit():
            sys.exit(f"--population expects band=count with band in {BANDS}, got {item!r}")
        population[band] = int(count)
        given.add(band)
    total = sum(population.values())
    return population, {band: population[band] / total for band in BANDS}, given


def per_detector(df, detector):
    """One row per unit for a detector; a re-scored unit keeps its latest row."""
    return df[df["check_type"] == detector].sort_values("score_id").drop_duplicates("unit_id", keep="last")


# 1. Positive rate per band, reweighted by the production population.

def band_table(recent, old, new, shares):
    rows = []
    for band in BANDS:
        units = recent[recent["band"] == band]
        o = per_detector(units, old)["positive"]
        n = per_detector(units, new)["positive"]
        rows.append({"band": band, "population_share": round(shares[band], 3),
                     "old_units": len(o), "old_rate": az.rate(o),
                     "new_units": len(n), "new_rate": az.rate(n),
                     "new_minus_old": None if o.empty or n.empty else round(float(n.mean() - o.mean()), 3)})
    return pd.DataFrame(rows)


def projection_table(table, shares, old, new, checks_per_month):
    def weighted(column):
        pairs = [(shares[b], r) for b, r in zip(table["band"], table[column]) if pd.notna(r)]
        return sum(s * r for s, r in pairs) if pairs else None

    rows = [{"detector": "production stored scores (band shares)", "projected_positive_rate": round(shares["high"], 4)},
            {"detector": f"{old} (fresh)", "projected_positive_rate": weighted("old_rate")},
            {"detector": f"{new} (fresh)", "projected_positive_rate": weighted("new_rate")}]
    for row in rows:
        rate = row["projected_positive_rate"]
        row["projected_positive_rate"] = None if rate is None else round(rate, 4)
        if checks_per_month is not None and rate is not None:
            row["projected_per_month"] = round(rate * checks_per_month, 1)
    old_rate, new_rate = rows[1]["projected_positive_rate"], rows[2]["projected_positive_rate"]
    ratio = None if not old_rate or new_rate is None else round(new_rate / old_rate, 3)
    return pd.DataFrame(rows), ratio


def chart_band_rates(table, old, new, out):
    fig, ax = plt.subplots(figsize=(6.5, 4), facecolor=az.SURFACE)
    positions = range(len(BANDS))
    width = 0.36
    for offset, detector, column in ((-width / 2, old, "old_rate"), (width / 2, new, "new_rate")):
        values = [0 if pd.isna(v) else float(v) for v in table[column]]
        bars = ax.bar([p + offset for p in positions], values, width=width - 0.03,
                      color=az.color_for(detector), label=detector)
        for bar, value in zip(bars, table[column]):
            if pd.isna(value):
                continue
            ax.annotate(f"{value:.0%}", (bar.get_x() + bar.get_width() / 2, bar.get_height()),
                        xytext=(0, 3), textcoords="offset points", ha="center", fontsize=9, color=az.INK)
    ax.set_xticks(list(positions))
    ax.set_xticklabels([BAND_LABELS[b] for b in BANDS])
    ax.set_ylim(0, 1.1)
    ax.set_ylabel("share of units above threshold", color=az.INK_SOFT)
    ax.set_xlabel("production score band of the same edit", color=az.INK_SOFT)
    ax.set_title("Positive rate by production score band", loc="left", color=az.INK, fontsize=12)
    ax.legend(frameon=False, fontsize=9, labelcolor=az.INK, loc="upper left")
    az.style(ax, percent=True)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


# 2. Reproducibility of the old detector against the stored production score.

def reproducibility(recent, old, threshold):
    d = per_detector(recent, old)
    d = d[d["source_max"].notna()].copy()
    if d.empty:
        return pd.DataFrame(), pd.DataFrame()
    d["diff"] = d["max_score"] - d["source_max"]
    d["abs_diff"] = d["diff"].abs()
    d["source_positive"] = d["source_max"] > threshold
    d["crossed"] = d["positive"] != d["source_positive"]
    stats = pd.DataFrame([{
        "units": len(d),
        "mean_abs_diff": round(float(d["abs_diff"].mean()), 4),
        "median_abs_diff": round(float(d["abs_diff"].median()), 4),
        "p95_abs_diff": round(float(d["abs_diff"].quantile(0.95)), 4),
        "max_abs_diff": round(float(d["abs_diff"].max()), 4),
        "share_abs_diff_over_0_1": round(float((d["abs_diff"] > 0.1).mean()), 3),
        "crossed_threshold": int(d["crossed"].sum()),
        "crossed_up": int((d["positive"] & ~d["source_positive"]).sum()),
        "crossed_down": int((~d["positive"] & d["source_positive"]).sum()),
        "pearson_r": round(float(d["max_score"].corr(d["source_max"])), 4),
    }])
    per_unit = (d[["unit_id", "url", "band", "source_max", "max_score", "diff", "crossed", "report_url"]]
                .rename(columns={"max_score": "fresh_max"})
                .sort_values("diff", key=lambda s: s.abs(), ascending=False))
    return stats, per_unit


def chart_reproducibility(per_unit, old, threshold, out):
    fig, ax = plt.subplots(figsize=(5.5, 5.5), facecolor=az.SURFACE)
    ax.plot([0, 1], [0, 1], color=az.GRID, linewidth=1)
    ax.scatter(per_unit["source_max"], per_unit["fresh_max"], s=36, color=az.color_for(old), alpha=0.7,
               edgecolors=az.SURFACE, linewidths=1)
    for line in (ax.axhline, ax.axvline):
        line(threshold, color=az.INK_SOFT, linewidth=1, linestyle=":")
    ax.set_xlim(-0.02, 1.02)
    ax.set_ylim(-0.02, 1.02)
    ax.set_xlabel("production max window score (stored)", color=az.INK_SOFT)
    ax.set_ylabel("fresh max window score", color=az.INK_SOFT)
    ax.set_title(f"{old}: fresh vs stored production score (n={len(per_unit)})",
                 loc="left", color=az.INK, fontsize=11)
    az.style(ax)
    ax.xaxis.grid(True, color=az.GRID, linewidth=0.8)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


# 3. Transitions at the threshold.

def transitions(df, old, new):
    o = per_detector(df, old).set_index("unit_id")
    n = per_detector(df, new).set_index("unit_id")
    both = o.index.intersection(n.index)
    if both.empty:
        return pd.DataFrame()
    frame = pd.DataFrame({"sample_name": o.loc[both, "sample_name"],
                          "old_model_version": o.loc[both, "model_version"].fillna("").astype(str),
                          "old": o.loc[both, "positive"].astype(bool), "new": n.loc[both, "positive"].astype(bool)})
    rows = []
    groups = list(frame.groupby(["sample_name", "old_model_version"], sort=True)) + [(("all samples", ""), frame)]
    for (sample, version), g in groups:
        rows.append({"sample_name": sample, "old_model_version": version, "units": len(g),
                     "both_positive": int((g["old"] & g["new"]).sum()),
                     "old_only": int((g["old"] & ~g["new"]).sum()),
                     "new_only": int((~g["old"] & g["new"]).sum()),
                     "neither": int((~g["old"] & ~g["new"]).sum())})
    return pd.DataFrame(rows)


# 4. Signals only the new detector reports.

def humanizer_tables(df, new):
    d = per_detector(df, new).copy()
    d["humanized_window_count"] = pd.to_numeric(d["humanized_window_count"], errors="coerce")
    d["max_humanizer_score"] = pd.to_numeric(d["max_humanizer_score"], errors="coerce")
    reported = d[d["humanized_window_count"].notna()]
    if reported.empty:
        return pd.DataFrame(), pd.DataFrame(), pd.DataFrame()
    per_sample = (reported.groupby("sample_name")
                  .agg(units=("unit_id", "size"),
                       humanized_units=("humanized_window_count", lambda s: int((s > 0).sum())),
                       humanized_windows=("humanized_window_count", lambda s: int(s.sum())),
                       max_humanizer_score=("max_humanizer_score", "max"))
                  .reset_index())
    scores = reported["max_humanizer_score"].dropna()
    distribution = pd.DataFrame([{"units": len(scores),
                                  "median": round(float(scores.median()), 4),
                                  "p90": round(float(scores.quantile(0.9)), 4),
                                  "p99": round(float(scores.quantile(0.99)), 4),
                                  "max": round(float(scores.max()), 4)}]) if not scores.empty else pd.DataFrame()
    flagged = reported[reported["humanized_window_count"] > 0]
    units = flagged[["sample_name", "unit_id", "url", "ground_truth", "provenance", "max_score",
                     "humanized_window_count", "max_humanizer_score", "report_url"]]
    return per_sample, distribution, units.sort_values("max_humanizer_score", ascending=False)


def label_table(df, detectors):
    rows = []
    for detector in detectors:
        d = per_detector(df, detector)
        d = d.assign(label=d["label"].fillna("(none)").astype(str),
                     fraction_mixed=pd.to_numeric(d["fraction_mixed"], errors="coerce"))
        for label, g in d.groupby("label", sort=True):
            rows.append({"detector": detector, "label": label, "units": len(g),
                         "share_above_threshold": az.rate(g["positive"]),
                         "median_max_score": round(float(g["max_score"].median()), 3),
                         "p90_max_score": round(float(g["max_score"].quantile(0.9)), 3),
                         "max_max_score": round(float(g["max_score"].max()), 3),
                         "mean_fraction_mixed": None if g["fraction_mixed"].isna().all()
                         else round(float(g["fraction_mixed"].mean()), 3)})
    return pd.DataFrame(rows)


def chart_label_distributions(df, detectors, threshold, out):
    fig, axes = plt.subplots(1, len(detectors), figsize=(4.5 * len(detectors), 4), sharey=True,
                             facecolor=az.SURFACE, squeeze=False)
    for ax, detector in zip(axes[0], detectors):
        d = per_detector(df, detector)
        labels = sorted(d["label"].fillna("(none)").astype(str).unique(),
                        key=lambda l: (list(LABEL_COLORS).index(l) if l in LABEL_COLORS else 99, l))
        placed = []  # (x, y) of direct labels already drawn on this panel
        for label in labels:
            subset = d[d["label"].fillna("(none)").astype(str) == label]["max_score"]
            if subset.empty:
                continue
            xs, ys = az.ecdf(subset)
            color = LABEL_COLORS.get(label, az.PALETTE[-1])
            ax.step(xs, ys, where="post", color=color, linewidth=2, label=f"{label} (n={len(subset)})")
            # Direct label beside the curve at its median. Labels usually live in different
            # score ranges; when two curves share one, the later label is stacked above.
            median_x = float(subset.median())
            left_side = median_x > 0.8
            y = 0.5
            for px, py in placed:
                if abs(px - median_x) < 0.2 and abs(py - y) < 0.08:
                    y = py + 0.09
            placed.append((median_x, y))
            ax.annotate(label, (median_x, y), xytext=(-8 if left_side else 8, 0), textcoords="offset points",
                        ha="right" if left_side else "left", va="center", fontsize=8, color=az.INK)
        ax.axvline(threshold, color=az.INK_SOFT, linewidth=1, linestyle=":")
        ax.set_title(f"{detector}: max score by document label", loc="left", fontsize=10, color=az.INK)
        ax.set_xlabel("max window score", color=az.INK_SOFT)
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1.08)
        ax.legend(frameon=False, fontsize=8, loc="upper left", labelcolor=az.INK)
        az.style(ax, percent=True)
    axes[0][0].set_ylabel("share of units at or below score", color=az.INK_SOFT)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


# 5. Window geometry.

def window_geometry(df, detectors):
    frames = []
    rows = []
    for detector in detectors:
        d = per_detector(df, detector).copy()
        d["window_count"] = pd.to_numeric(d["window_count"], errors="coerce")
        d = d[(d["window_count"] > 0) & d["word_count"].notna()]
        if d.empty:
            continue
        d["words_per_window"] = d["word_count"] / d["window_count"]
        frames.append(d)
        rows.append({"detector": detector, "units": len(d),
                     "median_words_per_window": round(float(d["words_per_window"].median()), 1),
                     "q1_words_per_window": round(float(d["words_per_window"].quantile(0.25)), 1),
                     "q3_words_per_window": round(float(d["words_per_window"].quantile(0.75)), 1),
                     "single_window_share": az.rate(d["window_count"] == 1),
                     "median_window_count": float(d["window_count"].median())})
    geometry = pd.concat(frames) if frames else pd.DataFrame()
    return pd.DataFrame(rows), geometry


def chart_window_geometry(geometry, detectors, out):
    fig, ax = plt.subplots(figsize=(6.5, 4.5), facecolor=az.SURFACE)
    x_max = float(geometry["word_count"].quantile(0.99))
    for detector in detectors:
        d = geometry[(geometry["check_type"] == detector) & (geometry["word_count"] <= x_max)]
        if d.empty:
            continue
        ax.scatter(d["word_count"], d["window_count"], s=24, color=az.color_for(detector), alpha=0.6,
                   edgecolors=az.SURFACE, linewidths=0.8, label=f"{detector} (n={len(d)})")
    ax.plot([0, x_max], [0, x_max / REFERENCE_WORDS_PER_WINDOW], color=az.INK_SOFT, linewidth=1, linestyle=":")
    ax.annotate(f"{REFERENCE_WORDS_PER_WINDOW} words per window", (x_max, x_max / REFERENCE_WORDS_PER_WINDOW),
                xytext=(-4, 4), textcoords="offset points", ha="right", fontsize=8, color=az.INK_SOFT)
    ax.set_xlim(0, x_max * 1.02)
    ax.set_ylim(0, None)
    ax.set_xlabel("words sent (units above the 99th percentile omitted)", color=az.INK_SOFT)
    ax.set_ylabel("windows returned", color=az.INK_SOFT)
    ax.set_title("Window geometry", loc="left", color=az.INK, fontsize=12)
    ax.legend(frameon=False, fontsize=9, labelcolor=az.INK, loc="upper left")
    az.style(ax)
    ax.xaxis.grid(True, color=az.GRID, linewidth=0.8)
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)


# 6. Baseline false positives by model version.

def baseline_by_version(df):
    base = df[df["baseline"]]
    rows = []
    for (detector, version), g in base.groupby(["check_type", base["model_version"].fillna("").astype(str)], sort=True):
        rows.append({"detector": detector, "model_version": version, "baseline_units": len(g),
                     "false_positives": int(g["positive"].sum()), "false_positive_rate": az.rate(g["positive"]),
                     "p99_max_score": round(float(g["max_score"].quantile(0.99)), 3),
                     "max_max_score": round(float(g["max_score"].max()), 3)})
    return pd.DataFrame(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("export_csv")
    parser.add_argument("--out", default="results/cutover")
    parser.add_argument("--threshold", type=float, default=0.9)
    parser.add_argument("--old", default="Pangram 3", help="detector production alerting uses now")
    parser.add_argument("--new", default="Pangram 4", help="detector it would move to")
    parser.add_argument("--recent-sample", default="recent_2026_09",
                        help="sample built by BuildAiDetectionSampleFromRecentScores (has band metadata)")
    parser.add_argument("--population", nargs="*", metavar="BAND=COUNT",
                        help="production checks per band for reweighting; any band left out "
                             "keeps its 2026-09-04 preflight count, marked [default] in the summary")
    parser.add_argument("--checks-per-month", type=float,
                        help="production checks per month, to express projected rates as alerts per month")
    parser.add_argument("--baseline-provenance", default="pre_llm_term")
    args = parser.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    df, failed = az.load(args.export_csv, None, None, args.baseline_provenance, args.threshold, "max")
    if df.empty:
        sys.exit("no scored rows")
    meta = df["metadata"].map(parse_metadata)
    df["band"] = meta.map(lambda m: m.get("band"))
    df["source_max"] = pd.to_numeric(meta.map(lambda m: m.get("source_max_ai_likelihood")), errors="coerce")
    population, shares, given_bands = parse_population(args.population)
    detectors = [args.old, args.new]
    recent = df[df["sample_name"] == args.recent_sample] if args.recent_sample else df[df["band"].notna()]

    bands = band_table(recent, args.old, args.new, shares)
    bands.to_csv(out / "band_rates.csv", index=False)
    projection, ratio = projection_table(bands, shares, args.old, args.new, args.checks_per_month)
    if bands[["old_rate", "new_rate"]].notna().any().any():
        chart_band_rates(bands, args.old, args.new, out / "band_rates.png")

    repro_stats, repro_units = reproducibility(recent, args.old, args.threshold)
    if not repro_units.empty:
        repro_units.to_csv(out / "reproducibility.csv", index=False)
        chart_reproducibility(repro_units, args.old, args.threshold, out / "reproducibility.png")

    moves = transitions(df, args.old, args.new)
    moves.to_csv(out / "transitions.csv", index=False)

    humanized_by_sample, humanizer_distribution, humanized_units = humanizer_tables(df, args.new)
    humanized_units.to_csv(out / "humanized_units.csv", index=False)
    labels = label_table(df, detectors)
    if not labels.empty:
        chart_label_distributions(df, [d for d in detectors if (df["check_type"] == d).any()],
                                  args.threshold, out / "label_score_distributions.png")

    geometry_table, geometry = window_geometry(df, detectors)
    if not geometry.empty:
        chart_window_geometry(geometry, detectors, out / "window_geometry.png")

    baseline = baseline_by_version(df)

    population_text = ", ".join(
        f"{b} {population[b]:,} ({shares[b]:.1%}){'' if b in given_bands else ' [default]'}"
        for b in BANDS
    )
    if given_bands and given_bands != set(BANDS):
        print(f"--population supplied for {sorted(given_bands)}; "
              f"{sorted(set(BANDS) - given_bands)} use the {DEFAULT_POPULATION_DATE} preflight counts.")
    summary = [
        "# Detector cutover analysis\n",
        f"Source: `{args.export_csv}`; old detector: {args.old}; new detector: {args.new}; "
        f"positive rule: max window score > {args.threshold}; scored rows: {len(df)}; failed rows dropped: {failed}.\n",
        f"\n## 1. Positive rate by production band (sample `{args.recent_sample}`)\n",
        f"Population weights (production checks per band): {population_text}.\n\n",
        az.markdown(bands),
        "\nProjected positive rate over the production population, and the ratio of new to old:\n\n",
        az.markdown(projection),
        f"\nnew / old ratio: {ratio}\n" if ratio is not None else "",
        f"\n## 2. {args.old} reproducibility (fresh vs stored production score)\n",
        az.markdown(repro_stats),
        f"{len(repro_units)} units in reproducibility.csv, largest differences first.\n" if not repro_units.empty else "",
        "\n## 3. Transitions at the threshold\n", az.markdown(moves),
        f"\n## 4. Signals only {args.new} reports\n",
        "\nHumanized windows per sample:\n\n", az.markdown(humanized_by_sample),
        "\nDistribution of max humanizer score across units that report one:\n\n", az.markdown(humanizer_distribution),
        f"\n{len(humanized_units)} units with at least one humanized window in humanized_units.csv.\n",
        "\nScore distribution by document label:\n\n", az.markdown(labels),
        "\n## 5. Window geometry\n", az.markdown(geometry_table),
        "\n## 6. Baseline false positives by model version\n", az.markdown(baseline),
        "\nCharts: band_rates.png, reproducibility.png, label_score_distributions.png, window_geometry.png. "
        "Data: band_rates.csv, reproducibility.csv, transitions.csv, humanized_units.csv.\n",
    ]
    (out / "cutover_summary.md").write_text("".join(summary))
    print("\n".join(str(p) for p in sorted(out.iterdir())))


if __name__ == "__main__":
    main()
