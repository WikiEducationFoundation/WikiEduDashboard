import React from 'react';
import PropTypes from 'prop-types';

import WikidataOverviewStats from '../wikidata_overview_stats';
import NamespaceOverviewStats from './namespace_overview_stats';

const OverviewStatsContent = ({ course, content, isInitialTab }) => {
  const title = content.statsTitle;
  const data = content.statsData;

  const homeWikiIsWikidata = course?.home_wiki?.project === 'wikidata';

  // Expanded when the home wiki is Wikidata, or when the user clicked over
  // to the Wikidata tab. Collapsed only if it's the initial (only) stats tab.
  const defaultExpanded = homeWikiIsWikidata || !isInitialTab;

  const statistics = (title === 'www.wikidata.org')
    ? (
      <WikidataOverviewStats
        statistics={data}
        isCourseOverview={true}
        defaultExpanded={defaultExpanded}
      />
    )
    : <NamespaceOverviewStats course={course} statistics={data} />;

  return (
    <div className="content-container">
      {title !== 'www.wikidata.org' && <h2 className="title">{title}</h2>}
      <div className="stats-data">
        {statistics}
      </div>
    </div>
  );
};

OverviewStatsContent.propTypes = {
  course: PropTypes.object,
  content: PropTypes.object.isRequired,
  isInitialTab: PropTypes.bool
};

export default OverviewStatsContent;
