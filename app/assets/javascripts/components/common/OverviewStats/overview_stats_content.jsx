import React from 'react';
import PropTypes from 'prop-types';

import WikidataOverviewStats from '../wikidata_overview_stats';
import NamespaceOverviewStats from './namespace_overview_stats';

const OverviewStatsContent = ({ course, content }) => {
  const title = content.statsTitle;
  const data = content.statsData;
  const statistics = (title === 'www.wikidata.org')
    ? <WikidataOverviewStats statistics={data} isCourseOverview={true}/>
    : <NamespaceOverviewStats course={course} statistics={data} />;

  return (
    <div className="content-container">
      <h2 className="title">{title}</h2>
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
