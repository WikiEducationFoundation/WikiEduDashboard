import React, { useState } from 'react';
import PropTypes from 'prop-types';

import OverviewStatsTab from './OverviewStats/overview_stats_tab';
import NamespaceOverviewStats from './OverviewStats/namespace_overview_stats';
import WikidataOverviewStats from './wikidata_overview_stats';

import { overviewStatsLabel } from '../../utils/wiki_utils';


const OverviewStatsTabs = ({ statistics }) => {
  const [currentTabId, setCurrentTabId] = useState(0);

  const onTabChange = (e) => {
    return setCurrentTabId(Number(e.currentTarget.id));
  };

  const statsList = [];
  const tabsList = [];

  let index = 0;
  Object.keys(statistics).forEach((wiki_ns_key) => {
    const statsTitle = overviewStatsLabel(wiki_ns_key);
    const statsData = statistics[wiki_ns_key];
    
    statsList.push({ statsTitle, statsData });
    tabsList.push(
      <OverviewStatsTab
        key={index}
        id={index}
        onClick={onTabChange}
        title={statsTitle}
        active={currentTabId === index}
      />
    )
    index += 1;
  });

  const title = statsList[currentTabId].statsTitle;
  const data = statsList[currentTabId].statsData;
  const content = (title === 'www.wikidata.org')
    ? <WikidataOverviewStats statistics={data} isCourseOverview={true}/>
    : <NamespaceOverviewStats statistics={data} />;

  return (
    <div className="overview-stats-tabs-container">
      <div className="tabs-container">
        {tabsList}
      </div>
      <div className="content-container">
        <h2 className="title">{title}</h2>
        <div className="stats-data">
          {content}
        </div>
      </div>
    </div>
  );
};

OverviewStatsTabs.propTypes = {
  statistics: PropTypes.object.isRequired
};

export default OverviewStatsTabs;
