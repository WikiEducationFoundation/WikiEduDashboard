import React, { useState } from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './OverviewStats/overview_stat';
import { onEnterOrSpace } from '../../utils/keyboard_handlers';

const TABS = [
  { id: 'summary', labelKey: 'metrics.summary' },
  { id: 'statements', labelKey: 'metrics.statements' },
  { id: 'content', labelKey: 'metrics.content' },
  { id: 'lexemes', labelKey: 'metrics.lexemes' }
];

const StatSection = ({ label, children, className = '' }) => (
  <div className={`stat-display__row ${className}`}>
    <h5 className="stats-label">{label}</h5>
    <div className="stat-display__value-group">
      {children}
    </div>
  </div>
);

const WikidataTab = ({ id, title, active, onClick }) => {
  const tabClass = `wikidata-tab${active ? ' active' : ''}`;
  return (
    <div
      role="tab"
      tabIndex={0}
      aria-selected={active}
      className={tabClass}
      onClick={onClick}
      onKeyDown={onEnterOrSpace(onClick)}
      id={`wikidata-tab-${id}`}
      aria-controls={`wikidata-panel-${id}`}
    >
      <p>{title}</p>
    </div>
  );
};

WikidataTab.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  active: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired
};

const SummaryTab = ({ statistics }) => (
  <>
    <StatSection label={I18n.t('metrics.general')}>
      <OverviewStat
        id="total-revisions"
        className="stat-display__value-small"
        stat={statistics['total revisions']}
        statMsg={I18n.t('metrics.total_revisions')}
        renderZero={true}
      />
      <OverviewStat
        id="merged"
        className="stat-display__value-small"
        stat={statistics['merged to']}
        statMsg={I18n.t('metrics.merged')}
        renderZero={true}
      />
      <OverviewStat
        id="merged-from"
        className="stat-display__value-small"
        stat={statistics['merged from']}
        statMsg={I18n.t('metrics.merged_from')}
        renderZero={true}
      />
      <OverviewStat
        id="interwiki-links"
        className="stat-display__value-small"
        stat={statistics['interwiki links added']}
        statMsg={I18n.t('metrics.interwiki_links_added')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('items.items')}>
      <OverviewStat
        id="items-created"
        className="stat-display__value-small"
        stat={statistics['items created']}
        statMsg={I18n.t('metrics.created')}
        renderZero={true}
      />
      <OverviewStat
        id="items-cleared"
        className="stat-display__value-small"
        stat={statistics['items cleared']}
        statMsg={I18n.t('metrics.cleared')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.claims')}>
      <OverviewStat
        id="claims-created"
        className="stat-display__value-small"
        stat={statistics['claims created']}
        statMsg={I18n.t('metrics.created')}
        renderZero={true}
      />
      <OverviewStat
        id="claims-changed"
        className="stat-display__value-small"
        stat={statistics['claims changed']}
        statMsg={I18n.t('metrics.changed')}
        renderZero={true}
      />
      <OverviewStat
        id="claims-removed"
        className="stat-display__value-small"
        stat={statistics['claims removed']}
        statMsg={I18n.t('metrics.removed')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.references')}>
      <OverviewStat
        id="references-added"
        className="stat-display__value-small"
        stat={statistics['references added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
        info={I18n.t('metrics.references_added_info')}
        infoId="references-added-info"
      />
    </StatSection>
  </>
);

SummaryTab.propTypes = {
  statistics: PropTypes.object.isRequired
};

const StatementsTab = ({ statistics }) => (
  <>
    <StatSection label={I18n.t('metrics.claims')}>
      <OverviewStat
        id="statements-claims-created"
        className="stat-display__value-small"
        stat={statistics['claims created']}
        statMsg={I18n.t('metrics.created')}
        renderZero={true}
      />
      <OverviewStat
        id="statements-claims-changed"
        className="stat-display__value-small"
        stat={statistics['claims changed']}
        statMsg={I18n.t('metrics.changed')}
        renderZero={true}
      />
      <OverviewStat
        id="statements-claims-removed"
        className="stat-display__value-small"
        stat={statistics['claims removed']}
        statMsg={I18n.t('metrics.removed')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.qualifiers')}>
      <OverviewStat
        id="qualifiers-added"
        className="stat-display__value-small"
        stat={statistics['qualifiers added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.references')}>
      <OverviewStat
        id="statements-references-added"
        className="stat-display__value-small"
        stat={statistics['references added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
        info={I18n.t('metrics.references_added_info')}
        infoId="statements-references-added-info"
      />
    </StatSection>
  </>
);

StatementsTab.propTypes = {
  statistics: PropTypes.object.isRequired
};

const ContentTab = ({ statistics }) => (
  <>
    <StatSection label={I18n.t('items.items')}>
      <OverviewStat
        id="content-items-created"
        className="stat-display__value-small"
        stat={statistics['items created']}
        statMsg={I18n.t('metrics.created')}
        renderZero={true}
      />
      <OverviewStat
        id="content-items-cleared"
        className="stat-display__value-small"
        stat={statistics['items cleared']}
        statMsg={I18n.t('metrics.cleared')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.labels')}>
      <OverviewStat
        id="labels-added"
        className="stat-display__value-small"
        stat={statistics['labels added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
      />
      <OverviewStat
        id="labels-changed"
        className="stat-display__value-small"
        stat={statistics['labels changed']}
        statMsg={I18n.t('metrics.changed')}
        renderZero={true}
      />
      <OverviewStat
        id="labels-removed"
        className="stat-display__value-small"
        stat={statistics['labels removed']}
        statMsg={I18n.t('metrics.removed')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.descriptions')}>
      <OverviewStat
        id="descriptions-added"
        className="stat-display__value-small"
        stat={statistics['descriptions added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
      />
      <OverviewStat
        id="descriptions-changed"
        className="stat-display__value-small"
        stat={statistics['descriptions changed']}
        statMsg={I18n.t('metrics.changed')}
        renderZero={true}
      />
      <OverviewStat
        id="descriptions-removed"
        className="stat-display__value-small"
        stat={statistics['descriptions removed']}
        statMsg={I18n.t('metrics.removed')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.aliases')}>
      <OverviewStat
        id="aliases-added"
        className="stat-display__value-small"
        stat={statistics['aliases added']}
        statMsg={I18n.t('metrics.added')}
        renderZero={true}
      />
      <OverviewStat
        id="aliases-changed"
        className="stat-display__value-small"
        stat={statistics['aliases changed']}
        statMsg={I18n.t('metrics.changed')}
        renderZero={true}
      />
      <OverviewStat
        id="aliases-removed"
        className="stat-display__value-small"
        stat={statistics['aliases removed']}
        statMsg={I18n.t('metrics.removed')}
        renderZero={true}
      />
    </StatSection>
    <StatSection label={I18n.t('metrics.other')}>
      <OverviewStat
        id="content-qualifiers-added"
        className="stat-display__value-small"
        stat={statistics['qualifiers added']}
        statMsg={I18n.t('metrics.qualifiers_added')}
        renderZero={true}
      />
      <OverviewStat
        id="redirects-created"
        className="stat-display__value-small"
        stat={statistics['redirects created']}
        statMsg={I18n.t('metrics.redirects_created')}
        renderZero={true}
      />
      <OverviewStat
        id="reverts-performed"
        className="stat-display__value-small"
        stat={statistics['reverts performed']}
        statMsg={I18n.t('metrics.reverts_performed')}
        renderZero={true}
      />
      <OverviewStat
        id="restorations-performed"
        className="stat-display__value-small"
        stat={statistics['restorations performed']}
        statMsg={I18n.t('metrics.restorations_performed')}
        renderZero={true}
      />
    </StatSection>
  </>
);

ContentTab.propTypes = {
  statistics: PropTypes.object.isRequired
};

const LexemesTab = ({ statistics }) => (
  <StatSection label={I18n.t('items.lexeme')}>
    <OverviewStat
      id="lexeme-created"
      className="stat-display__value-small"
      stat={statistics['lexeme items created']}
      statMsg={I18n.t('metrics.created')}
      renderZero={true}
    />
  </StatSection>
);

LexemesTab.propTypes = {
  statistics: PropTypes.object.isRequired
};

const TAB_PANELS = {
  summary: SummaryTab,
  statements: StatementsTab,
  content: ContentTab,
  lexemes: LexemesTab
};

const WikidataOverviewStats = ({ statistics, isCourseOverview }) => {
  const [activeTab, setActiveTab] = useState('summary');

  let containerClass = 'wikidata-stats-container';
  let title = 'Wikidata stats';
  if (isCourseOverview) {
    containerClass = 'wikidata-stats-container course-overview';
    title = null;
  }

  const onTabChange = (e) => {
    const tabId = e.currentTarget.id.replace('wikidata-tab-', '');
    setActiveTab(tabId);
  };

  const ActivePanel = TAB_PANELS[activeTab];

  return (
    <div className={containerClass}>
      <h2 className="wikidata-stats-title">{title}</h2>
      <div className="wikidata-tabs" role="tablist">
        {TABS.map(tab => (
          <WikidataTab
            key={tab.id}
            id={tab.id}
            title={I18n.t(tab.labelKey)}
            active={activeTab === tab.id}
            onClick={onTabChange}
          />
        ))}
      </div>
      <div
        className="wikidata-display"
        role="tabpanel"
        id={`wikidata-panel-${activeTab}`}
        aria-labelledby={`wikidata-tab-${activeTab}`}
      >
        <ActivePanel statistics={statistics} />
      </div>
    </div>
  );
};

WikidataOverviewStats.propTypes = {
  statistics: PropTypes.object.isRequired,
  isCourseOverview: PropTypes.bool
};

export default WikidataOverviewStats;
