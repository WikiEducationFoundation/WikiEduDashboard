import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useSelector } from 'react-redux';
import Wp10Graph from './wp10_graph.jsx';
import ArticleSizeGraph from './article_size_graph.jsx';
import Loading from '../common/loading.jsx';
import request from '../../utils/request.js';
import { toWikiDomain } from '../../utils/wiki_utils.js';
import { userHighlightColors } from '../common/ArticleViewer/constants/colors';

// Editors who aren't course participants all share one muted color.
const OTHER_EDITOR_COLOR = '#999999';

const ArticleGraphs = ({ article, course_id, courseStart, courseEnd }) => {
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
  const [selectedRadio, setSelectedRadio] = useState('wp10_score');
  const [articleData, setArticleData] = useState(null);

  const elementRef = useRef(null);

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

  function getData() {
    if (articleData) {
      return;
    }
    const articledataUrl = `/articles/${article_id}/revision_score?course_id=${course_id}`;
    request(articledataUrl)
      .then(resp => resp.json())
      .then((data) => {
        setArticleData(data);
      });
  }

  function handleShowGraph() {
    getData();
    setShowGraph(true);
  }

  function handleHideGraph() {
    setArticleData(null);
    setShowGraph(false);
  }

  // Give each participant who edited this article a distinct color, taken in
  // order from the front of the shared editor palette (highest-contrast hues);
  // every other editor gets the muted "other" color. Color is precomputed onto
  // each datum so both graphs and the legend stay consistent.
  const { coloredData, legendEntries } = useMemo(() => {
    if (!articleData) return { coloredData: null, legendEntries: [] };
    const colorFor = {};
    let hasOtherEditors = false;
    articleData.forEach((rev) => {
      if (!participantUsernames.has(rev.username)) {
        hasOtherEditors = true;
      } else if (!(rev.username in colorFor)) {
        const index = Object.keys(colorFor).length;
        colorFor[rev.username] = userHighlightColors[index % userHighlightColors.length];
      }
    });

    const colored = articleData.map(rev => ({
      ...rev,
      color: colorFor[rev.username] || OTHER_EDITOR_COLOR
    }));

    const entries = Object.keys(colorFor).map(username => ({ label: username, color: colorFor[username] }));
    if (hasOtherEditors) {
      entries.push({ label: I18n.t('articles.editor_other'), color: OTHER_EDITOR_COLOR });
    }
    return { coloredData: colored, legendEntries: entries };
  }, [articleData, participantUsernames]);

  const graphId = `vega-graph-${article_id}`;
  const dataIncludesWp10 = articleData?.[0]?.wp10;

  const sharedGraphProps = {
    graphid: graphId,
    graphWidth: 500,
    graphHeight: 300,
    articleData: coloredData,
    courseStart,
    courseEnd,
    wikiUrl
  };

  let graph;
  if (!articleData) {
    graph = <Loading />;
  } else if (dataIncludesWp10 && selectedRadio === 'wp10_score') {
    graph = <Wp10Graph {...sharedGraphProps} />;
  } else {
    graph = <ArticleSizeGraph {...sharedGraphProps} />;
  }

  // Only offer the toggle when wp10 scores are available; otherwise the
  // article-size graph is the only view, so no choice is needed.
  let toggle = null;
  if (dataIncludesWp10) {
    toggle = (
      <span className="graph-toggle" role="group" aria-label={I18n.t('articles.article_development')}>
        <button
          type="button"
          className={`graph-toggle__btn${selectedRadio === 'wp10_score' ? ' active' : ''}`}
          aria-pressed={selectedRadio === 'wp10_score'}
          onClick={() => setSelectedRadio('wp10_score')}
        >
          {I18n.t('articles.wp10')}
        </button>
        <button
          type="button"
          className={`graph-toggle__btn${selectedRadio === 'article_size' ? ' active' : ''}`}
          aria-pressed={selectedRadio === 'article_size'}
          onClick={() => setSelectedRadio('article_size')}
        >
          {I18n.t('articles.article_size')}
        </button>
      </span>
    );
  }

  // Explanatory copy for the active view (operator-authored).
  let docText = null;
  if (articleData) {
    const doc = dataIncludesWp10 && selectedRadio === 'wp10_score'
      ? I18n.t('articles.wp10_doc')
      : I18n.t('articles.article_size_doc');
    if (doc) docText = doc;
  }

  const legend = legendEntries.length > 0 && (
    <ul className="graph-legend">
      {legendEntries.map(entry => (
        <li key={entry.label} className="graph-legend__item">
          <span className="graph-legend__swatch" style={{ backgroundColor: entry.color }} />
          {entry.label}
        </li>
      ))}
    </ul>
  );

  const className = `vega-graph ${showGraph ? '' : 'hidden'}`;

  return (
    <button type="button" onClick={handleShowGraph} className="inline">
      {I18n.t('articles.article_development')}
      <div className={className} ref={elementRef}>
        <div className="radio-row">
          {toggle}
        </div>
        {graph}
        {legend}
        {docText && <p className="graph-doc">{docText}</p>}
      </div>
    </button>
  );
};

export default ArticleGraphs;
