/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { Link, useLocation } from 'react-router-dom';
import { DATASETS } from './descriptions';
import { datasetPath, INDEX_PATH } from './data';

// The top of a dataset's page: the way back to the index, a switch to the other dataset, and
// the dataset's title. Arriving from another page starts at the top, unless the address names
// a section to scroll to.
const DatasetHeader = ({ current }) => {
  const { hash } = useLocation();
  useEffect(() => {
    if (!hash) window.scrollTo({ top: 0, behavior: 'instant' });
  }, [current]);
  const dataset = DATASETS.find(item => item.key === current);

  return (
    <>
      <p><Link to={INDEX_PATH}>← AI detector comparison</Link></p>
      <nav className="detector-comparison__dataset-nav" aria-label="Datasets">
        {DATASETS.map(item => (
          <Link
            key={item.key} to={datasetPath(item.key)} aria-current={item.key === current ? 'page' : undefined}
            className={`detector-comparison__dataset-tab${item.key === current ? ' detector-comparison__dataset-tab--current' : ''}`}
          >
            {item.label}
          </Link>
        ))}
      </nav>
      <h1>{dataset.title}</h1>
    </>
  );
};

DatasetHeader.propTypes = { current: PropTypes.oneOf(DATASETS.map(item => item.key)).isRequired };

export default DatasetHeader;
