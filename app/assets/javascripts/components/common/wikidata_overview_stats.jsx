import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './OverviewStats/overview_stat';
import I18n from 'i18n-js';

const WikidataOverviewStats = ({ statistics, classNameSuffix }) => {
  let className = "wikidata-stats-container";
  if (classNameSuffix) className = `${className} ${classNameSuffix}`;

  return (
    <div className={className}>
      <h2 className="wikidata-stats-title">Wikidata stats</h2>
      <div className="wikidata-display">
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.general')}</h5>
          <div className="stat-display__value-group">
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
              stat = {statistics['merged to']}
              statMsg={I18n.t('metrics.merged')}
              renderZero={true}
            />
            <OverviewStat
              id="interwiki-links"
              className="stat-display__value-small"
              stat = {statistics['interwiki links added']}
              statMsg={I18n.t('metrics.interwiki_links_added')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('items.items')}</h5>
          <div className="stat-display__value-group">
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
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.claims')}</h5>
          <div className="stat-display__value-group">
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
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.labels')}</h5>
          <div className="stat-display__value-group">
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
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">Descriptions</h5>
          <div className="stat-display__value-group">
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
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">Aliases</h5>
          <div className="stat-display__value-group">
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
          </div>
        </div>
        <div className="stat-display__row double-row">
          <h5 className="stats-label">Other</h5>
          <div className="stat-display__value-group double">
            <OverviewStat
              id="qualifiers-added"
              className="stat-display__value-small"
              stat={statistics['qualifiers added']}
              statMsg={I18n.t('metrics.qualifiers_added')}
              renderZero={true}
            />
            <OverviewStat
              id="references-added"
              className="stat-display__value-small"
              stat={statistics['references added']}
              statMsg={I18n.t('metrics.references_added')}
              renderZero={true}
              info={I18n.t('metrics.references_added_info')}
              infoId="references-added-info"
            />
            <OverviewStat
              id="redirects-created"
              className="stat-display__value-small"
              stat={statistics['redirects created']}
              statMsg={I18n.t('metrics.redirects_created')}
              renderZero={true}
            />
          </div>
          <div className="stat-display__value-group double">
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
              renderZero={true} i
            />
            <OverviewStat
              id="other-updates"
              className="stat-display__value-small"
              stat={statistics['other updates']}
              statMsg={I18n.t('metrics.other_updates')}
              renderZero={true}
            />
          </div>
        </div>


      </div>
    </div>
    );
};

WikidataOverviewStats.propTypes = {
  statistics: PropTypes.object,
  classNameSuffix: PropTypes.string
};

  export default WikidataOverviewStats;
