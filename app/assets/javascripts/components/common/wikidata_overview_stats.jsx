import React, { useState } from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './OverviewStats/overview_stat';

const WikidataOverviewStats = ({ statistics, isCourseOverview = false }) => {
  const [expanded, setExpanded] = useState(!isCourseOverview);
  const title = I18n.t('metrics.data_wikidata');
  const categories = [
    {
      key: 'general',
      label: I18n.t('metrics.general'),
      stats: [
        ['total revisions', 'total-revisions', I18n.t('metrics.total_revisions')],
        ['merged to', 'merged', I18n.t('metrics.merged')],
        ['merged from', 'merged-from', I18n.t('metrics.merged_from')],
        ['interwiki links added', 'interwiki-links', I18n.t('metrics.interwiki_links_added')]
      ]
    },
    {
      key: 'items',
      label: I18n.t('items.items'),
      stats: [
        ['items created', 'items-created', I18n.t('metrics.created')],
        ['items cleared', 'items-cleared', I18n.t('metrics.cleared')]
      ]
    },
    {
      key: 'claims',
      label: I18n.t('metrics.claims'),
      stats: [
        ['claims created', 'claims-created', I18n.t('metrics.created')],
        ['claims changed', 'claims-changed', I18n.t('metrics.changed')],
        ['claims removed', 'claims-removed', I18n.t('metrics.removed')]
      ]
    },
    {
      key: 'labels',
      label: I18n.t('metrics.labels'),
      stats: [
        ['labels added', 'labels-added', I18n.t('metrics.added')],
        ['labels changed', 'labels-changed', I18n.t('metrics.changed')],
        ['labels removed', 'labels-removed', I18n.t('metrics.removed')]
      ]
    },
    {
      key: 'descriptions',
      label: 'Descriptions',
      stats: [
        ['descriptions added', 'descriptions-added', I18n.t('metrics.added')],
        ['descriptions changed', 'descriptions-changed', I18n.t('metrics.changed')],
        ['descriptions removed', 'descriptions-removed', I18n.t('metrics.removed')]
      ]
    },
    {
      key: 'aliases',
      label: 'Aliases',
      stats: [
        ['aliases added', 'aliases-added', I18n.t('metrics.added')],
        ['aliases changed', 'aliases-changed', I18n.t('metrics.changed')],
        ['aliases removed', 'aliases-removed', I18n.t('metrics.removed')]
      ]
    },
    {
      key: 'other',
      label: 'Other',
      double: true,
      stats: [
        ['qualifiers added', 'qualifiers-added', I18n.t('metrics.qualifiers_added')],
        ['references added', 'references-added', I18n.t('metrics.references_added'),
          I18n.t('metrics.references_added_info'), 'references-added-info'],
        ['redirects created', 'redirects-created', I18n.t('metrics.redirects_created')],
        ['reverts performed', 'reverts-performed', I18n.t('metrics.reverts_performed')],
        ['restorations performed', 'restorations-performed', I18n.t('metrics.restorations_performed')],
        ['other updates', 'other-updates', I18n.t('metrics.other_updates')]
      ]
    },
    {
      key: 'lexeme',
      label: I18n.t('items.lexeme'),
      stats: [['lexeme items created', 'lexeme-created', I18n.t('metrics.created')]]
    },
    {
      key: 'language',
      label: I18n.t('metrics.language'),
      stats: [
        ['language added', 'language-added', I18n.t('metrics.added')],
        ['language changed', 'language-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'lexical-category',
      label: I18n.t('metrics.lexical_category'),
      stats: [
        ['lexical category added', 'lexical-category-added', I18n.t('metrics.added')],
        ['lexical category changed', 'lexical-category-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'lemmas',
      label: I18n.t('metrics.lemmas'),
      stats: [
        ['lemmas added', 'lemmas-added', I18n.t('metrics.added')],
        ['lemmas removed', 'lemmas-removed', I18n.t('metrics.removed')],
        ['lemmas changed', 'lemmas-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'forms',
      label: I18n.t('metrics.forms'),
      stats: [
        ['forms added', 'forms-added', I18n.t('metrics.added')],
        ['forms removed', 'forms-removed', I18n.t('metrics.removed')],
        ['forms changed', 'forms-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'form-claims',
      label: I18n.t('metrics.form_claims'),
      stats: [
        ['form claims added', 'form-claims-added', I18n.t('metrics.added')],
        ['form claims removed', 'form-claims-removed', I18n.t('metrics.removed')],
        ['form claims changed', 'form-claims-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'form-references',
      label: I18n.t('metrics.form_references'),
      stats: [
        ['form references added', 'form-references-added', I18n.t('metrics.added')],
        ['form references removed', 'form-references-removed', I18n.t('metrics.removed')],
        ['form references changed', 'form-references-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'form-qualifiers',
      label: I18n.t('metrics.form_qualifiers'),
      stats: [
        ['form qualifiers added', 'form-qualifiers-added', I18n.t('metrics.added')],
        ['form qualifiers removed', 'form-qualifiers-removed', I18n.t('metrics.removed')],
        ['form qualifiers changed', 'form-qualifiers-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'senses',
      label: I18n.t('metrics.senses'),
      stats: [
        ['senses added', 'senses-added', I18n.t('metrics.added')],
        ['senses removed', 'senses-removed', I18n.t('metrics.removed')],
        ['senses changed', 'senses-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'glosses',
      label: I18n.t('metrics.glosses'),
      stats: [
        ['glosses added', 'glosses-added', I18n.t('metrics.added')],
        ['glosses removed', 'glosses-removed', I18n.t('metrics.removed')],
        ['glosses changed', 'glosses-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'sense-claims',
      label: I18n.t('metrics.sense_claims'),
      stats: [
        ['sense claims added', 'sense-claims-added', I18n.t('metrics.added')],
        ['sense claims removed', 'sense-claims-removed', I18n.t('metrics.removed')],
        ['sense claims changed', 'sense-claims-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'sense-references',
      label: I18n.t('metrics.sense_references'),
      stats: [
        ['sense references added', 'sense-references-added', I18n.t('metrics.added')],
        ['sense references removed', 'sense-references-removed', I18n.t('metrics.removed')],
        ['sense references changed', 'sense-references-changed', I18n.t('metrics.changed')]
      ]
    },
    {
      key: 'sense-qualifiers',
      label: I18n.t('metrics.sense_qualifiers'),
      stats: [
        ['sense qualifiers added', 'sense-qualifiers-added', I18n.t('metrics.added')],
        ['sense qualifiers removed', 'sense-qualifiers-removed', I18n.t('metrics.removed')],
        ['sense qualifiers changed', 'sense-qualifiers-changed', I18n.t('metrics.changed')]
      ]
    }
  ];

  const nonZeroStats = stats => stats.filter(([name]) => {
    const value = statistics[name];
    return value !== undefined && Number(value) !== 0;
  });

  const renderStat = ([name, id, statMsg, info, infoId]) => (
    <OverviewStat
      key={id}
      id={id}
      className="stat-display__value-small"
      stat={statistics[name]}
      statMsg={statMsg}
      renderZero={false}
      info={info}
      infoId={infoId}
    />
  );

  const visibleCategories = categories
    .map(category => ({ ...category, stats: nonZeroStats(category.stats) }))
    .filter(category => category.stats.length > 0);

  return (
    <div className={`wikidata-stats-container${isCourseOverview ? ' course-overview' : ''}`}>
      <button
        type="button"
        className="wikidata-stats-toggle"
        aria-expanded={expanded}
        aria-controls="wikidata-stats-content"
        onClick={() => setExpanded(!expanded)}
      >
        <span className="wikidata-stats-title">{title}</span>
        <span aria-hidden="true">{expanded ? '−' : '+'}</span>
      </button>
      {expanded && (
        <div className="wikidata-display" id="wikidata-stats-content">
          {visibleCategories.map(category => (
            <div
              className={`stat-display__row${category.double ? ' double-row' : ''}`}
              key={category.key}
            >
              <h5 className="stats-label">{category.label}</h5>
              {category.double
                ? [category.stats.slice(0, 3), category.stats.slice(3)].map((stats, index) => (
                  <div className="stat-display__value-group double" key={index}>
                    {stats.map(renderStat)}
                  </div>
                ))
                : (
                  <div className="stat-display__value-group">
                    {category.stats.map(renderStat)}
                  </div>
                )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

WikidataOverviewStats.propTypes = {
  statistics: PropTypes.object.isRequired,
  isCourseOverview: PropTypes.bool
};

export default WikidataOverviewStats;
