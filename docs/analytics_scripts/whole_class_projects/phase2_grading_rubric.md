# Phase 2 grading rubric: added Wikipedia content

You are grading text that was added to a Wikipedia article. Each input line is
one item (JSON). Grade each item independently, on its content alone.

## Item fields

- `article_title`
- `added_passage`: the added paragraphs, converted to plain text. Citation
  markers like `[3]` show where references were placed; section headings
  appear as `== Heading ==`. Conversion is automatic, so stray markup or
  leftover fragments are not the writer's fault.
- `cited_claims_in_passage`: how many cited sentences the passage has.
- `claims`: up to 5 cited sentences sampled from the passage. Each has:
  - `marker`, `sentence` (the sentence the citation marker closes)
  - `citation`: fields parsed from the reference (title, url, doi, author,
    publisher, date...)
  - `source.status`: `ok` if source text was retrieved; otherwise
    `no_url` (e.g. a book), `http_error`, `no_text` or `fetch_error`
  - `source.excerpt`: when `ok`, up to four ~2,000-character windows from the
    source, automatically chosen as the best keyword matches for the sentence
    (separated by `[...]`). Read all of them; the excerpt may still miss the
    relevant part of a long source.

## Per-claim grades

`support`:
- `supported`: the excerpt states what the sentence claims.
- `partially_supported`: the excerpt supports part of the claim, or a weaker or
  vaguer version of it; or the sentence adds detail, emphasis or
  interpretation the excerpt doesn't contain.
- `not_supported`: the excerpt addresses the sentence's specific subject but
  does not say what the sentence claims.
- `contradicted`: the excerpt says something incompatible with the claim.
- `unverifiable`: no source text (`status` not `ok`), or the excerpt doesn't
  address the claim's subject at all, so the right passage may simply not have
  been extracted.

`source_mismatch`: `true` if the source as retrieved seems to be a different
work or topic than the citation describes, or entirely unrelated to the claim
(a possible fabricated or misattributed citation). Otherwise `false`. Error
pages, paywalls and cookie walls are not mismatches — they make the claim
`unverifiable`.

`note`: one short sentence.

## Per-item grades (on the whole `added_passage`)

- `encyclopedic_tone`: 1–5 (5 = neutral, formal, encyclopedic; 1 = essay,
  advocacy, first person or informal).
- `original_research`: `none`, `minor` or `major` — analysis, synthesis or
  conclusions that go beyond summarizing sources.
- `essay_like`: `none`, `minor` or `major` — persuasive or argumentative
  framing, reflection, thesis statements.
- `promotional`: `none`, `minor` or `major` — puffery, peacock terms, advert
  tone.
- `unsourced_substantive`: `none`, `some` or `many` — substantive factual
  sentences with no citation marker.
- `ai_style_prose`: `none`, `some` or `strong` — hallmarks of LLM-generated
  text (generic summarizing sentences, stock phrases such as "plays a crucial
  role" or "rich tapestry", uniform list-like structure, vague attributions).
  This is supplementary; do not let it drive the other grades.
- `overall_quality`: 1–5, as a Wikipedia contribution.
- `notes`: one or two sentences, citing specifics.

## Output

One JSON object per item, one per line (JSONL), in input order:

```json
{"item_id": "item_001", "claims": [{"marker": 3, "support": "partially_supported", "source_mismatch": false, "note": "Source says violence rose after WWI, not in 1895."}], "encyclopedic_tone": 4, "original_research": "minor", "essay_like": "none", "promotional": "none", "unsourced_substantive": "some", "ai_style_prose": "none", "overall_quality": 3, "notes": "Well organized; a few interpretive sentences go beyond the sources."}
```

Include one entry in `claims` for every claim in the item, in the same order.
