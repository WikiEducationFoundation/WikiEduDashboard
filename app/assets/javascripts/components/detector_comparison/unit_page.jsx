/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Link, useParams } from 'react-router-dom';
import {
  APPROXIMATE_HIGHLIGHT, CONDITIONS, DETECTORS, HIGHLIGHT_HELP, MODELS, REFERENCE_ROWS, SOURCE_FORMATS
} from './descriptions';
import { datasetPath, fetchOverview, fetchUnit, formatScore, isGenerated, shade, topicOfPair } from './data';
import VerdictChip from './verdict_chip';
import { topicPath } from './topic_matrix';
import AuthorshipNote from './authorship_note';

const PRIOR_ARTICLE = '{prior_article}';

const unitTitle = (unit, topic) => {
  const version = REFERENCE_ROWS.find(row => row.version && row.version === unit.factors.version);
  if (version) return `${unit.factors.topic}: ${version.label}`;
  if (unit.ground_truth === 'human') return `Student's additions: ${topic || unit.sample}`;
  if (unit.provenance === 'agpedia') return `Agpedia: ${unit.factors.topic}${unit.factors.excerpt === 'lead' ? ' (lead)' : ''}`;
  const model = MODELS[unit.factors.model]?.label || unit.factors.model;
  const condition = CONDITIONS[unit.metadata.condition]?.label || unit.metadata.condition;
  return `${model} · ${condition} · ${unit.factors.topic}`;
};

const FACT_LABELS = [
  ['sample', 'Sample'], ['words', 'Words'], ['runner', 'Generated with'], ['tool_version', 'Tool version'],
  ['generated_at', 'Generated'], ['rev_timestamp', 'Revision date'], ['fetched_at', 'Collected'], ['web_searches', 'Web searches'], ['web_fetches', 'Pages fetched'],
  ['prior_overlap', 'Copied from the prior article'], ['human_prompt', 'Human prompt'],
  ['agpedia_operators', 'Agpedia operators'], ['agpedia_agents', 'Agpedia agents'], ['agpedia_rev_date', 'Agpedia revision date'],
];

const Facts = ({ unit }) => {
  const values = { ...unit.factors, ...unit.metadata, sample: unit.sample, words: unit.words };
  const condition = CONDITIONS[unit.metadata.condition];
  const model = MODELS[unit.factors.model];
  return (
    <dl className="detector-comparison__facts">
      {model && <><dt>Model</dt><dd>{model.label}: {model.detail}</dd></>}
      {condition && <><dt>Condition</dt><dd>{condition.label}: {condition.description}</dd></>}
      {FACT_LABELS.filter(([key]) => values[key] !== undefined && values[key] !== null && values[key] !== '').map(([key, label]) => (
        <React.Fragment key={key}><dt>{label}</dt><dd>{String(values[key])}</dd></React.Fragment>
      ))}
      {unit.url && <><dt>Source</dt><dd><a href={unit.url}>{unit.url}</a></dd></>}
    </dl>
  );
};

Facts.propTypes = { unit: PropTypes.object.isRequired };

const scoreCells = (score) => {
  const { summary } = score;
  if (summary.vendor === 'pangram') return `max window ${formatScore(summary.max_score)}, mean ${formatScore(summary.mean_window_score)}`;
  return `document ${formatScore(summary.document_score)}, max ${summary.vendor === 'open_pangram' ? 'window' : 'block'} ${formatScore(summary.max_score)}`;
};

const Results = ({ scores }) => (
  <div className="detector-comparison__scroll">
    <table className="table">
      <thead>
        <tr><th scope="col">Detector</th><th scope="col">Verdict</th><th scope="col">Scores</th><th scope="col">Windows</th><th scope="col">Report</th></tr>
      </thead>
      <tbody>
        {scores.map(score => (
          <tr key={score.check_type}>
            <th scope="row">
              {DETECTORS[score.check_type]?.label || score.check_type}
              {DETECTORS[score.check_type]?.research && <span className="detector-comparison__research"> research only</span>}
            </th>
            {score.error ? (
              <td colSpan={4}>The call failed: {score.error}</td>
            ) : (
              <>
                <td>
                  <VerdictChip verdict={{ flagged: score.flagged, label: score.summary.label }} />
                  {score.summary.vendor === 'pangram' && score.summary.max_score > 0.9 && <span className="detector-comparison__alert"> would alert</span>}
                </td>
                <td>{scoreCells(score)}</td>
                <td>{score.summary.window_count ?? '–'}</td>
                <td>{score.summary.report_url ? <a href={score.summary.report_url}>Vendor report</a> : '–'}</td>
              </>
            )}
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

Results.propTypes = { scores: PropTypes.array.isRequired };

const HighlightedText = ({ text, highlight, windows }) => {
  if (!highlight) return <div className="detector-comparison__text">{text}</div>;
  return (
    <>
      <p className="detector-comparison__help">
        {HIGHLIGHT_HELP} ({DETECTORS[highlight.check_type]?.label || highlight.check_type}){highlight.approximate && ` ${APPROXIMATE_HIGHLIGHT}`}
      </p>
      <div className="detector-comparison__text">
        {highlight.parts.map((part, index) => {
          if (part.window === null) return <span key={index}>{part.text}</span>;
          const window = windows[part.window];
          return (
            <mark key={index} className="detector-comparison__window" style={shade(window?.score || 0)} title={`Window ${part.window + 1}: ${formatScore(window?.score)}`}>
              {part.text}
            </mark>
          );
        })}
      </div>
    </>
  );
};

HighlightedText.propTypes = { text: PropTypes.string.isRequired, highlight: PropTypes.object, windows: PropTypes.array };

const PangramWindows = ({ score }) => (
  <div className="detector-comparison__scroll">
    <table className="table">
      <caption>{DETECTORS[score.check_type]?.label || score.check_type} windows</caption>
      <thead>
        <tr><th scope="col">Window</th><th scope="col">Words</th><th scope="col">Label</th><th scope="col">Score</th><th scope="col">Confidence</th><th scope="col">Humanized</th></tr>
      </thead>
      <tbody>
        {score.windows.map((window, index) => (
          <tr key={index}>
            <td>{index + 1}</td>
            <td>{window.words}</td>
            <td>{window.label}</td>
            <td style={shade(window.score || 0)}>{formatScore(window.score)}</td>
            <td>{window.confidence}</td>
            <td>{window.humanized === undefined || window.humanized === null ? '–' : `${window.humanized ? 'yes' : 'no'} (${formatScore(window.humanizer_score)})`}</td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

PangramWindows.propTypes = { score: PropTypes.object.isRequired };

const Prompts = ({ prompts, priorArticleUrl }) => (
  <ol className="detector-comparison__prompts">
    {prompts.map((prompt, index) => (
      <li key={index}>
        {prompt.split(PRIOR_ARTICLE).map((piece, pieceIndex) => (
          <React.Fragment key={pieceIndex}>
            {pieceIndex > 0 && (priorArticleUrl ? <a href={priorArticleUrl}>[the article as it stood before the student’s term]</a> : '[the article as it stood before the student’s term]')}
            {piece}
          </React.Fragment>
        ))}
      </li>
    ))}
  </ol>
);

Prompts.propTypes = { prompts: PropTypes.array.isRequired, priorArticleUrl: PropTypes.string };

const UnitPage = () => {
  const { id } = useParams();
  const [unit, setUnit] = useState(null);
  const [overview, setOverview] = useState(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setUnit(null);
    setFailed(false);
    fetchUnit(id).then(setUnit).catch(() => setFailed(true));
    fetchOverview().then(setOverview).catch(() => {});
    window.scrollTo(0, 0);
  }, [id]);

  if (failed) return <div className="container detector-comparison"><p>This text could not be loaded.</p></div>;
  if (!unit) return <div className="container detector-comparison"><p>Loading…</p></div>;

  const pairTopic = overview && topicOfPair(overview.units, unit.id);
  const topic = unit.factors.topic || pairTopic;
  const pangramScores = unit.scores.filter(score => score.windows?.length);
  const highlightWindows = unit.highlight && unit.scores.find(score => score.check_type === unit.highlight.check_type)?.windows;
  const blocks = unit.scores.filter(score => score.blocks?.length);

  return (
    <div className="container detector-comparison">
      <p><Link to="/detector_comparison">← AI detector comparison</Link></p>
      <h1>{unitTitle(unit, pairTopic)}</h1>
      <Facts unit={unit} />

      <section>
        <h2>Detector results</h2>
        <Results scores={unit.scores} />
      </section>

      <section>
        <h2>Text the detectors scored</h2>
        <HighlightedText text={unit.text} highlight={unit.highlight} windows={highlightWindows || []} />
      </section>

      {pangramScores.map(score => <PangramWindows key={score.check_type} score={score} />)}
      {blocks.map(score => (
        <p key={score.check_type} className="detector-comparison__help">
          {DETECTORS[score.check_type]?.label || score.check_type} block scores (Originality keeps no block text or positions):{' '}
          {score.blocks.map(block => formatScore(block.ai)).join(', ')}
        </p>
      ))}

      {unit.prompts?.length > 0 && (
        <section>
          <h2>{unit.prompts.length > 1 ? `Prompts (${unit.prompts.length} turns)` : 'Prompt'}</h2>
          <p className="detector-comparison__help">The system prompt was replaced with “You are a helpful assistant.”</p>
          <Prompts prompts={unit.prompts} priorArticleUrl={unit.prior_article_url} />
        </section>
      )}

      {unit.source_text && (
        <section>
          <details>
            <summary>Text as written ({SOURCE_FORMATS[unit.source_format] || unit.source_format})</summary>
            <pre className="detector-comparison__source">{unit.source_text}</pre>
          </details>
        </section>
      )}

      {overview && topic && overview.units.some(other => isGenerated(other) && other.factors.topic === topic) && (
        <p className="detector-comparison__topic-link"><Link to={topicPath(topic)}>Every text on {topic}</Link></p>
      )}
      {unit.datasets?.includes('known_human') && (
        <p className="detector-comparison__topic-link"><Link to={datasetPath('known_human')}>Every known-human text</Link></p>
      )}

      <AuthorshipNote />
    </div>
  );
};

export default UnitPage;
