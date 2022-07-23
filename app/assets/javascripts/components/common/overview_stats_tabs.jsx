import React, { useState } from 'react';
import PropTypes from 'prop-types';

import OverviewStatsTab from './OverviewStats/overview_stats_tab';
import NamespaceOverviewStats from './OverviewStats/namespace_overview_stats';
import WikidataOverviewStats from './wikidata_overview_stats';

import ArticleUtils from '../../utils/article_utils';


const OverviewStatsTabs = ({ statistics }) => {
  const [currentTabId, setCurrentTabId] = useState(0);

  const onTabChange = (e) => {
    return setCurrentTabId(Number(e.currentTarget.id));
  };

  const statsDataList = [];
  let index = 0;
  Object.keys(statistics).forEach((wiki_ns_key) => {
    const id = index;
    const statsTitle = ArticleUtils.overviewStatsTitle(wiki_ns_key);
    const data = statistics[wiki_ns_key];
    statsDataList.push({ id, statsTitle, data });
    index += 1;
  });

  const tabsList = statsDataList.map((obj) => {
    return (
      <OverviewStatsTab
        key={obj.id}
        id={obj.id}
        onClick={onTabChange}
        title={obj.statsTitle}
        active={currentTabId === obj.id}
      />
    );
  });

  const title = statsDataList[currentTabId].statsTitle;
  const data = statsDataList[currentTabId].data;
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
