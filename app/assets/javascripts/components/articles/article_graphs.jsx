import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useSelector } from 'react-redux';
import Wp10Graph from './wp10_graph.jsx';
import ArticleSizeGraph from './article_size_graph.jsx';
import Loading from '../common/loading.jsx';
import request from '../../utils/request.js';
import { toWikiDomain } from '../../utils/wiki_utils.js';
import { fetchArticleRevisions, fetchBaselineRevision } from '../../utils/article_revision_api.js';
import { userHighlightColors } from '../common/ArticleViewer/authorship/colors';

// Editors who aren't course participants all share one muted color.
const OTHER_EDITOR_COLOR = '#999999';
// Rough per-revision LiftWing time, used only to pace the scoring progress bar.
const SCORE_SECONDS_PER_EDIT = 0.5;

// Popover sizing (see _graphs.styl). The popover is border-box, 90vw wide and
// capped at 1200px, with 10px of padding on each side. graphWidth is the chart's
// *total* SVG width: the graph specs use fit-x autosize, so Vega lays the y-axis
// (ticks, labels, rotated title) out inside this width rather than adding it on
// the outside. But vega-embed then wraps the SVG in a shrink-to-fit
// `.vega-embed` div with `padding-right: 38px` — a gutter for the absolutely
// positioned "⋯" actions menu — so the wrapper is graphWidth + 38 wide. We
// subtract the popover padding, a vertical scrollbar, and that gutter so the
// whole wrapper (menu included) fits without forcing a horizontal scrollbar
// that would clip the menu.
const POPOVER_VW_FRACTION = 0.9;
const POPOVER_MAX_WIDTH = 1200;
const POPOVER_PADDING = 20;
const SCROLLBAR_ALLOWANCE = 24;
const VEGA_EMBED_ACTIONS_GUTTER = 38;
const MIN_GRAPH_WIDTH = 320;

// Determinate-ish progress bar shown while wp10 scoring runs. It fills toward
// 95% over an estimate (count x per-edit time), then the graph replaces it when
// scores arrive. Cancel lets the user bail back to the instant Article Size view.
const ScoringProgress = ({ count, onCancel }) => {
  const [filled, setFilled] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => setFilled(true), 50);
    return () => clearTimeout(timer);
  }, []);

  const status = I18n.t('articles.scoring_status', { count });
  const seconds = Math.max(2, count * SCORE_SECONDS_PER_EDIT);

  return (
    <div className="scoring-progress">
      {status && <p className="scoring-progress__label">{status}</p>}
      <div className="scoring-progress__track">
        <div
          className="scoring-progress__fill"
          style={{ width: filled ? '95%' : '0%', transitionDuration: `${seconds}s` }}
        />
      </div>
      <button
        type="button"
        className="button dark"
        onClick={(e) => { e.stopPropagation(); onCancel(); }}
      >
        {I18n.t('application.cancel')}
      </button>
    </div>
  );
};

const ArticleGraphs = ({ article, courseStart, courseEnd }) => {
  const { id: article_id } = article;
  const wikiUrl = `https://${toWikiDomain({ language: article.language, project: article.project })}`;

  // Course users are already in the store (fetched at course load), so editor
  // identification happens client-side.
  const courseUsers = useSelector(state => state.users.users);
  const participantUsernames = useMemo(
    () => new Set(courseUsers.map(user => user.username)),
    [courseUsers]
  );

  const [showGraph, setShowGraph] = useState(false);
  const [selectedRadio, setSelectedRadio] = useState('article_size');
  const [revisions, setRevisions] = useState(null);
  const [baseline, setBaseline] = useState(null);
  const [scores, setScores] = useState(null);
  const [scoring, setScoring] = useState(false);

  const elementRef = useRef(null);
  const abortRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      const element = elementRef.current;
      if (element && !element.contains(event.target)) {
        handleHideGraph();
      }
    };
    const handlePressEscapeKey = (event) => {
      if (event.key === 'Escape') {
        handleHideGraph();
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handlePressEscapeKey);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handlePressEscapeKey);
    };
  }, []);

  // Fetch the revision list straight from the MediaWiki API. This is all the
  // Article Size graph needs, so it can render immediately.
  function loadRevisions() {
    if (revisions) return;
    const controller = new AbortController();
    abortRef.current = controller;
    Promise.all([
      fetchArticleRevisions({ article, start: courseStart, end: courseEnd, signal: controller.signal }),
      fetchBaselineRevision({ article, start: courseStart, signal: controller.signal })
    ])
      .then(([edits, baselineRev]) => { setRevisions(edits); setBaseline(baselineRev); })
      .catch((e) => { if (e.name !== 'AbortError') setRevisions([]); });
  }

  // wp10 scoring is server-side and slower, so it only runs when the user asks
  // for the Structural Completeness view.
  function loadScores() {
    if (scores || scoring || !revisions || revisions.length === 0) return;
    setScoring(true);
    const controller = new AbortController();
    abortRef.current = controller;
    const revIds = revisions.map(rev => rev.rev_id);
    if (baseline && !revIds.includes(baseline.rev_id)) revIds.push(baseline.rev_id);
    request(`/articles/${article_id}/revision_score`, {
      method: 'POST',
      body: JSON.stringify({ rev_ids: revIds }),
      signal: controller.signal
    })
      .then(resp => resp.json())
      .then((data) => { setScores(data); setScoring(false); })
      .catch((e) => { if (e.name !== 'AbortError') setScoring(false); });
  }

  function handleShowGraph() {
    setShowGraph(true);
    loadRevisions();
  }

  function handleHideGraph() {
    if (abortRef.current) abortRef.current.abort();
    setShowGraph(false);
  }

  function selectView(view) {
    setSelectedRadio(view);
    if (view === 'wp10_score') loadScores();
  }

  function cancelScoring() {
    if (abortRef.current) abortRef.current.abort();
    setScoring(false);
    setSelectedRadio('article_size');
  }

  // Give each participant who edited this article a distinct color, taken in
  // order from the front of the shared editor palette (highest-contrast hues);
  // every other editor gets the muted color. Color (and wp10, once scored) is
  // precomputed onto each datum so both graphs and the legend stay consistent.
  const { coloredData, legendEntries } = useMemo(() => {
    if (!revisions) return { coloredData: null, legendEntries: [] };
    const colorFor = {};
    let hasOtherEditors = false;
    revisions.forEach((rev) => {
      if (!participantUsernames.has(rev.username)) {
        hasOtherEditors = true;
      } else if (!(rev.username in colorFor)) {
        const index = Object.keys(colorFor).length;
        colorFor[rev.username] = userHighlightColors[index % userHighlightColors.length];
      }
    });

    const editData = revisions.map(rev => ({
      ...rev,
      participant: participantUsernames.has(rev.username),
      color: colorFor[rev.username] || OTHER_EDITOR_COLOR,
      wp10: scores ? scores[String(rev.rev_id)] : undefined,
      baseline: false
    }));

    // The article's state at course start, plotted at the start date with no
    // point, so the line/area has no empty gap before the first in-course edit.
    let data = editData;
    if (baseline && !revisions.some(rev => rev.rev_id === baseline.rev_id)) {
      data = [{
        rev_id: baseline.rev_id,
        date: new Date(courseStart).toISOString(),
        characters: baseline.characters,
        username: undefined,
        participant: false,
        color: OTHER_EDITOR_COLOR,
        wp10: scores ? scores[String(baseline.rev_id)] : undefined,
        baseline: true
      }, ...editData];
    }

    const entries = Object.keys(colorFor)
      .map(username => ({ label: username, color: colorFor[username], participant: true }));
    if (hasOtherEditors) {
      entries.push({ label: I18n.t('articles.editor_other'), color: OTHER_EDITOR_COLOR, participant: false });
    }
    return { coloredData: data, legendEntries: entries };
  }, [revisions, baseline, scores, participantUsernames, courseStart]);

  const graphId = `vega-graph-${article_id}`;
  const showingWp10 = selectedRadio === 'wp10_score';

  // Size the chart to the popover's inner content width (read once when
  // opened; it doesn't live-resize). With fit-x autosize the whole chart,
  // axis included, fits within graphWidth, so the SVG never spills past the
  // popover. See the constants above.
  const popoverWidth = Math.min(POPOVER_MAX_WIDTH, window.innerWidth * POPOVER_VW_FRACTION);
  const graphWidth = Math.max(
    MIN_GRAPH_WIDTH,
    Math.round(popoverWidth - POPOVER_PADDING - SCROLLBAR_ALLOWANCE - VEGA_EMBED_ACTIONS_GUTTER)
  );
  const graphHeight = Math.round(graphWidth * 0.42);
  const sharedGraphProps = {
    graphid: graphId,
    graphWidth,
    graphHeight,
    articleData: coloredData,
    courseStart,
    courseEnd,
    wikiUrl
  };

  let graph;
  if (!revisions) {
    graph = <Loading />;
  } else if (showingWp10 && !scores) {
    graph = <ScoringProgress count={revisions.length} onCancel={cancelScoring} />;
  } else if (showingWp10) {
    graph = <Wp10Graph {...sharedGraphProps} />;
  } else {
    graph = <ArticleSizeGraph {...sharedGraphProps} />;
  }

  const toggle = (
    <span className="graph-toggle" role="group" aria-label={I18n.t('articles.article_development')}>
      <button
        type="button"
        className={`graph-toggle__btn${showingWp10 ? '' : ' active'}`}
        aria-pressed={!showingWp10}
        onClick={(e) => { e.stopPropagation(); selectView('article_size'); }}
      >
        {I18n.t('articles.article_size')}
      </button>
      <button
        type="button"
        className={`graph-toggle__btn${showingWp10 ? ' active' : ''}`}
        aria-pressed={showingWp10}
        onClick={(e) => { e.stopPropagation(); selectView('wp10_score'); }}
      >
        {I18n.t('articles.wp10')}
      </button>
    </span>
  );

  // Explanatory copy for the active view (operator-authored).
  const doc = showingWp10 ? I18n.t('articles.wp10_doc') : I18n.t('articles.article_size_doc');
  const docText = revisions ? doc : null;

  const legend = legendEntries.length > 0 && (
    <ul className="graph-legend">
      {legendEntries.map(entry => (
        <li key={entry.label} className="graph-legend__item">
          <span
            className={`graph-legend__swatch${entry.participant ? '' : ' graph-legend__swatch--other'}`}
            style={{ backgroundColor: entry.color }}
          />
          {entry.label}
        </li>
      ))}
    </ul>
  );

  const className = `vega-graph ${showGraph ? '' : 'hidden'}`;

  // The popover is a sibling of the trigger, not a child: it holds its own
  // buttons (view toggle, cancel), and a <button> cannot legally contain other
  // buttons. The popover is position:fixed, so DOM placement doesn't affect where
  // it renders.
  return (
    <>
      <button type="button" onClick={handleShowGraph} className="inline">
        {I18n.t('articles.article_development')}
      </button>
      <div className={className} ref={elementRef}>
        <div className="radio-row">
          {toggle}
        </div>
        {graph}
        {legend}
        {docText && <p className="graph-doc">{docText}</p>}
      </div>
    </>
  );
};

export default ArticleGraphs;
