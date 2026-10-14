/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { DATASETS, INDEX_AUTHORSHIP_NOTE } from './descriptions';
import { datasetPath, fetchIndex } from './data';
import { SELECTION_KEYS } from './selection';
import CuratedViews from './curated_views';
import AuthorshipNote, { AuthorshipDagger } from './authorship_note';

// The index: the operator's preamble and conclusions, then a way into each dataset.
const IndexPage = () => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  const { hash, search } = useLocation();
  const navigate = useNavigate();

  // A table selection in the address comes from a link made before the 16-topic table had a
  // page of its own; send it there.
  const legacySelection = SELECTION_KEYS.some(key => new URLSearchParams(search).has(key));
  useEffect(() => {
    if (legacySelection) navigate(`${datasetPath('topics')}${search}${hash}`, { replace: true });
  }, [legacySelection]);

  useEffect(() => {
    fetchIndex().then(setData).catch(() => setFailed(true));
  }, []);
  // Links such as "All conclusions" name a section: scroll to it once the page has rendered.
  useEffect(() => {
    if (data && hash) document.getElementById(decodeURIComponent(hash.slice(1)))?.scrollIntoView();
  }, [data, hash]);

  if (failed) return <div className="container detector-comparison"><p>The comparison data could not be loaded.</p></div>;
  if (!data || legacySelection) return <div className="container detector-comparison"><p>Loading…</p></div>;

  const intro = data.intro || { preamble_html: '', views: [] };
  return (
    <div className="container detector-comparison">
      <h1>AI detector comparison</h1>
      {/* Operator-written Markdown rendered with HTML escaped (RenderDetectorComparisonIntro). */}
      <div className="detector-comparison__preamble" dangerouslySetInnerHTML={{ __html: intro.preamble_html }} />
      <CuratedViews views={intro.views} />

      <section className="detector-comparison__datasets">
        <h2>Datasets<AuthorshipDagger /></h2>
        <ul className="detector-comparison__dataset-cards">
          {DATASETS.map(dataset => (
            <li key={dataset.key} className="detector-comparison__dataset-card">
              <h3><Link to={datasetPath(dataset.key)}>{dataset.title}</Link></h3>
              <p>{dataset.description}</p>
              {data.counts?.[dataset.key] !== undefined && (
                <p className="detector-comparison__help">{data.counts[dataset.key].toLocaleString()} texts</p>
              )}
            </li>
          ))}
        </ul>
      </section>

      <AuthorshipNote note={INDEX_AUTHORSHIP_NOTE} />
    </div>
  );
};

export default IndexPage;
