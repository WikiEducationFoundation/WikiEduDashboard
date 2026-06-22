import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './OverviewStats/overview_stat';

const WikidataOverviewStats = ({ statistics, isCourseOverview }) => {
  let containerClass = 'wikidata-stats-container';
  let title = 'Wikidata stats';
  if (isCourseOverview) {
    containerClass = 'wikidata-stats-container course-overview';
    title = null;
  }
  return (
    <div className={containerClass}>
      <h2 className="wikidata-stats-title">{title}</h2>
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
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('items.lexeme')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="lexeme-created"
              className="stat-display__value-small"
              stat={statistics['lexeme items created']}
              statMsg={I18n.t('metrics.created')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.language')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="language-added"
              className="stat-display__value-small"
              stat={statistics['language added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="language-changed"
              className="stat-display__value-small"
              stat={statistics['language changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.lexical_category')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="lexical-category-added"
              className="stat-display__value-small"
              stat={statistics['lexical category added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="lexical-category-changed"
              className="stat-display__value-small"
              stat={statistics['lexical category changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.lemmas')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="lemmas-added"
              className="stat-display__value-small"
              stat={statistics['lemmas added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="lemmas-removed"
              className="stat-display__value-small"
              stat={statistics['lemmas removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="lemmas-changed"
              className="stat-display__value-small"
              stat={statistics['lemmas changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.forms')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="forms-added"
              className="stat-display__value-small"
              stat={statistics['forms added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="forms-removed"
              className="stat-display__value-small"
              stat={statistics['forms removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="forms-changed"
              className="stat-display__value-small"
              stat={statistics['forms changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.form_claims')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="form-claims-added"
              className="stat-display__value-small"
              stat={statistics['form claims added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="form-claims-removed"
              className="stat-display__value-small"
              stat={statistics['form claims removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="form-claims-changed"
              className="stat-display__value-small"
              stat={statistics['form claims changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.form_references')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="form-references-added"
              className="stat-display__value-small"
              stat={statistics['form references added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="form-references-removed"
              className="stat-display__value-small"
              stat={statistics['form references removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="form-references-changed"
              className="stat-display__value-small"
              stat={statistics['form references changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.form_qualifiers')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="form-qualifiers-added"
              className="stat-display__value-small"
              stat={statistics['form qualifiers added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="form-qualifiers-removed"
              className="stat-display__value-small"
              stat={statistics['form qualifiers removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="form-qualifiers-changed"
              className="stat-display__value-small"
              stat={statistics['form qualifiers changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.senses')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="senses-added"
              className="stat-display__value-small"
              stat={statistics['senses added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="senses-removed"
              className="stat-display__value-small"
              stat={statistics['senses removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="senses-changed"
              className="stat-display__value-small"
              stat={statistics['senses changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.glosses')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="glosses-added"
              className="stat-display__value-small"
              stat={statistics['glosses added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="glosses-removed"
              className="stat-display__value-small"
              stat={statistics['glosses removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="glosses-changed"
              className="stat-display__value-small"
              stat={statistics['glosses changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.sense_claims')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="sense-claims-added"
              className="stat-display__value-small"
              stat={statistics['sense claims added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-claims-removed"
              className="stat-display__value-small"
              stat={statistics['sense claims removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-claims-changed"
              className="stat-display__value-small"
              stat={statistics['sense claims changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.sense_references')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="sense-references-added"
              className="stat-display__value-small"
              stat={statistics['sense references added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-references-removed"
              className="stat-display__value-small"
              stat={statistics['sense references removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-references-changed"
              className="stat-display__value-small"
              stat={statistics['sense references changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
        <div className="stat-display__row">
          <h5 className="stats-label">{I18n.t('metrics.sense_qualifiers')}</h5>
          <div className="stat-display__value-group">
            <OverviewStat
              id="sense-qualifiers-added"
              className="stat-display__value-small"
              stat={statistics['sense qualifiers added']}
              statMsg={I18n.t('metrics.added')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-qualifiers-removed"
              className="stat-display__value-small"
              stat={statistics['sense qualifiers removed']}
              statMsg={I18n.t('metrics.removed')}
              renderZero={true}
            />
            <OverviewStat
              id="sense-qualifiers-changed"
              className="stat-display__value-small"
              stat={statistics['sense qualifiers changed']}
              statMsg={I18n.t('metrics.changed')}
              renderZero={true}
            />
          </div>
        </div>
      </div>
    </div>
    );
};

WikidataOverviewStats.propTypes = {
  statistics: PropTypes.object.isRequired,
  isCourseOverview: PropTypes.bool
};

  export default WikidataOverviewStats;
