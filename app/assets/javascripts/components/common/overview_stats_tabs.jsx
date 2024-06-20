import React, { useState } from 'react';
import PropTypes from 'prop-types';

import OverviewStatsTab from './OverviewStats/overview_stats_tab';
import OverviewStatsContent from './OverviewStats/overview_stats_content';

import { wikiNamespaceLabel } from '../../utils/wiki_utils';


const OverviewStatsTabs = ({ course, statistics }) => {
  if (Object.keys(statistics).length === 0) { return null; }

  const [currentTabId, setCurrentTabId] = useState(0);

  const onTabChange = (e) => {
    const tabId = e.currentTarget.id;
    const tabIdNumber = Number(tabId.split('-')[1]);
    return setCurrentTabId(tabIdNumber);
  };

  const statsList = [];
  const tabsList = [];

  let index = 0;
  Object.keys(statistics).forEach((wiki_ns_key) => {
    let statsTitle;
    if (wiki_ns_key.includes('namespace')) {
      const wiki = wiki_ns_key.split('-')[0];
      const namespace = wiki_ns_key.split('-')[2];
      statsTitle = wikiNamespaceLabel(wiki, namespace);
    } else { statsTitle = wiki_ns_key; }
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
    );
    index += 1;
  });

  const content = <OverviewStatsContent course={course} content={statsList[currentTabId]} />;
  // Hide tabs container if there is only one tab
  const tabsClass = `tabs-container${(tabsList.length === 1) ? ' hide' : ''}`;

  return (
    <div className="overview-stats-tabs-container">
      <div className={tabsClass}>
        {tabsList}
      </div>
      {content}
    </div>
  );
};

OverviewStatsTabs.propTypes = {
  statistics: PropTypes.object.isRequired
};

export default OverviewStatsTabs;
