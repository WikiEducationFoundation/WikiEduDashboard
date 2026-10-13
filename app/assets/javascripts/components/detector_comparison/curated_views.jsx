/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React from 'react';
import PropTypes from 'prop-types';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { selectionParams, showsSelection } from './selection';
import { datasetPath, INDEX_PATH } from './data';

export const TABLE_ID = 'detector-comparison-table';
export const LIST_ID = 'detector-comparison-conclusions';
const CUES = { topics: 'Show in the 16-topic table →', known_human: 'Show in the known-human table →' };

// Operator-written Markdown, rendered with HTML escaped (RenderDetectorComparisonIntro).
const Gloss = ({ html }) => <div className="detector-comparison__view-description" dangerouslySetInnerHTML={{ __html: html }} />;
Gloss.propTypes = { html: PropTypes.string.isRequired };

// A view's dataset page with its selection applied.
const viewPath = view => `${datasetPath(view.dataset)}?${selectionParams(view.selection)}`;

// The operator's conclusions on the index: each card opens its dataset's table with a saved
// selection. The whole card is clickable; the title is the link for keyboard and screen-reader
// use, and links in the gloss work as links.
const CuratedViews = ({ views }) => {
  const navigate = useNavigate();
  if (!views.length) return null;

  const onCardClick = (event, view) => {
    if (event.target.closest('a')) return;
    navigate(viewPath(view));
  };

  return (
    <ol className="detector-comparison__views" id={LIST_ID}>
      {views.map(view => (
        // The card is a larger click target for the title link, which keyboard users reach.
        // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions
        <li key={view.key} onClick={event => onCardClick(event, view)} className="detector-comparison__view">
          <h3 className="detector-comparison__view-heading">
            <Link className="detector-comparison__view-button" to={viewPath(view)}>{view.title}</Link>
          </h3>
          <Gloss html={view.description_html} />
          <p className="detector-comparison__view-cue" aria-hidden="true">{CUES[view.dataset] || CUES.topics}</p>
        </li>
      ))}
    </ol>
  );
};

CuratedViews.propTypes = { views: PropTypes.array.isRequired };

// The conclusion a dataset's table is showing, above the table so its text sits next to the data.
export const ActiveView = ({ views, dataset }) => {
  const [params] = useSearchParams();
  const active = views.find(view => view.dataset === dataset && showsSelection(params, view.selection));
  if (!active) return null;
  return (
    <section className="detector-comparison__active-view" aria-live="polite">
      <p className="detector-comparison__view-cue">Showing</p>
      <h2 className="detector-comparison__view-heading">{active.title}</h2>
      <Gloss html={active.description_html} />
      <p><Link to={`${INDEX_PATH}#${LIST_ID}`}>All conclusions</Link></p>
    </section>
  );
};

ActiveView.propTypes = { views: PropTypes.array.isRequired, dataset: PropTypes.string.isRequired };

export default CuratedViews;
