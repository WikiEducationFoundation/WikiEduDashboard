import React, { useState } from 'react';
import PropTypes from 'prop-types';

import WikiOverviewTabs from './OverviewStats/wiki_overview_tabs';
import NamespaceOverviewStats from './OverviewStats/namespace_overview_stats';
import WikidataOverviewStats from './wikidata_overview_stats';

import ArticleUtils from '../../utils/article_utils';


const WikiOverviewStats = ({ wikidataStats, wikiNamespaceStats }) => {
  const [currentTabId, setCurrentTabId] = useState(0);

  const getTabTitle = (id, wiki) => {
    const project = wiki.split(".")[1];
    var ns_title = ArticleUtils.NamespaceTitleFromId[id];
    if (typeof(ns_title) !== "string") ns_title = ns_title[project];
    return `${ns_title} (${wiki})`;
  }
  
  const getContentTitle = (id, wiki) => {
    const project = wiki.split(".")[1];
    var ns_title = ArticleUtils.NamespaceTitleFromId[id];
    if (typeof(ns_title) !== "string") ns_title = ns_title[project];
    return `Wiki: ${wiki}, Namespace: ${ns_title}`;
  }

  const onTabChange = (e) => {
    return setCurrentTabId(e.currentTarget.id);
  }

  const hasWikidataStats = wikidataStats !== null;
  const isWikidata = (hasWikidataStats && currentTabId == 0);

  let statsData = [];
  if (hasWikidataStats) {
    statsData.push({ id: 0, tabTitle: "Wikidata", data: wikidataStats });
  }

  let i = hasWikidataStats ? 1 : 0;
  statsData = statsData.concat(
    Object.entries(wikiNamespaceStats).map(([wiki, stats]) => {
      return Object.entries(stats).map(([ns, data]) => {
        const id = i++;
        const tabTitle = getTabTitle(ns, wiki);
        const contentTitle = getContentTitle(ns, wiki);
        return { id, tabTitle, contentTitle, data };
      })
  }).reduce((a, b) => a.concat(b)));

  const tabsList = statsData.map((obj) => {
    return (
      <WikiOverviewTabs 
        id={obj.id}
        onClick={onTabChange}
        title={obj.tabTitle} 
        active={currentTabId == obj.id}/>
    )
  });

  const contentTitle = (isWikidata) ? null : statsData[currentTabId]["contentTitle"];
  const data = statsData[currentTabId]["data"];
  const content = (isWikidata)
    ? <WikidataOverviewStats statistics={data} /> 
    : <NamespaceOverviewStats data={data} />;

  return(
    <div className="wiki-overview-stats-container">
      <div className="tabs-container">
        {tabsList}
      </div>
      <div className="content-container">
        <h2 className="title">{contentTitle}</h2>
        <div className="stats-data">
          {content}
        </div>
      </div>
    </div>
  );
};

WikiOverviewStats.propTypes = {
  wikidataStats: PropTypes.object,
  wikiNamespaceStats: PropTypes.object
};

export default WikiOverviewStats;
