import React, { useState } from 'react';
import PropTypes from 'prop-types';

import OverviewStatsTab from './OverviewStats/overview_stats_tab';
import NamespaceOverviewStats from './OverviewStats/namespace_overview_stats';
import WikidataOverviewStats from './wikidata_overview_stats';

import ArticleUtils from '../../utils/article_utils';


const OverviewStatsTabs = ({ statistics }) => {
  const [currentTabId, setCurrentTabId] = useState(0);

  const getTabTitle = (ns_id, wiki) => {
    const project = wiki.split('.')[1];
    let ns_title = ArticleUtils.NamespaceIdMapping[ns_id];
    if (typeof (ns_title) !== 'string') ns_title = ns_title[project];
    return `${I18n.t(`namespace.${ns_title}`)} (${wiki})`;
  };

  const getContentTitle = (ns_id, wiki) => {
    const project = wiki.split('.')[1];
    let ns_title = ArticleUtils.NamespaceIdMapping[ns_id];
    if (typeof (ns_title) !== 'string') ns_title = ns_title[project];
    return `Stats for ${I18n.t(`namespace.${ns_title}`)} (${wiki})`;
  };

  const onTabChange = (e) => {
    return setCurrentTabId(Number(e.currentTarget.id));
  };

  const hasWikidataStats = () => {
    if (statistics['www.wikidata.org']) return true;
    return false;
  }

  const statsDataList = [];
  // if there are wikidata overview stats, they should be displayed on first tab
  if (hasWikidataStats) {
    statsDataList.push({ 
      id: 0,
      tabTitle: 'Wikidata',
      contentTitle: null, // title for wikidata stats already exists in WikidataOverviewStats component
      data: statistics['www.wikidata.org']
    });
  }

  let index = hasWikidataStats ? 1 : 0;
  Object.keys(statistics).forEach((wiki_ns) => {
    if (!wiki_ns.includes('namespace')) return; // return if it doesn't contain namespace stats
    
    const ns_id = Number(wiki_ns.split('-')[2]); // namespace id
    const wiki = wiki_ns.split('-')[0];
    const id = index;
    const tabTitle = getTabTitle(ns_id, wiki);
    const contentTitle = getContentTitle(ns_id, wiki);
    const data = statistics[wiki_ns];
    statsDataList.push({ id, tabTitle, contentTitle, data });
    index += 1;
  });

  const tabsList = statsDataList.map((obj) => {
    return (
      <OverviewStatsTab
        key={obj.id}
        id={obj.id}
        onClick={onTabChange}
        title={obj.tabTitle}
        active={currentTabId === obj.id}
      />
    );
  });

  const contentTitle = statsDataList[currentTabId].contentTitle;
  const data = statsDataList[currentTabId].data;
  const content = (hasWikidataStats && currentTabId === 0)
    ? <WikidataOverviewStats statistics={data} classNameSuffix={'wiki-overview'}/>
    : <NamespaceOverviewStats statistics={data} />;

  return (
    <div className="overview-stats-tabs-container">
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

OverviewStatsTabs.propTypes = {
  statistics: PropTypes.object.isRequired
};

export default OverviewStatsTabs;
