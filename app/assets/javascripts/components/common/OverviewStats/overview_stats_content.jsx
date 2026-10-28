import React from 'react';
import PropTypes from 'prop-types';

import WikidataOverviewStats from '../wikidata_overview_stats';
import NamespaceOverviewStats from './namespace_overview_stats';

const OverviewStatsContent = ({ course, content }) => {
  const title = content.statsTitle;
  const data = content.statsData;

  // This logic checks if the course home wiki is Wikidata
  const homeWikiIsWikidata = course?.home_wiki?.project === 'wikidata';

  const statistics = (title === 'www.wikidata.org')
    ? (
      <WikidataOverviewStats
        statistics={data}
        isCourseOverview={true}
        defaultExpanded={homeWikiIsWikidata}
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
  content: PropTypes.object.isRequired
};

export default OverviewStatsContent;
