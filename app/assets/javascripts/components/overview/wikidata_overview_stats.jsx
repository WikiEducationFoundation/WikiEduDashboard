import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './overview_stat';

const WikidataOverviewStats = ({ statistics, valueClass }) => {
    const itemsInfo = [[statistics['items cleared'], I18n.t('metrics.items_cleared')]];
    const claimsInfo = [[statistics['claims changed'], I18n.t('metrics.claims_changed')],
    [statistics['claims removed'], I18n.t('metrics.claims_removed')]];
    const aliasesInfo = [[statistics['aliases changed'], I18n.t('metrics.aliases_changed')],
    [statistics['aliases removed'], I18n.t('metrics.aliases_removed')]];
    const descriptionsInfo = [[statistics['descriptions changed'], I18n.t('metrics.descriptions_changed')],
    [statistics['descriptions removed'], I18n.t('metrics.descriptions_removed')]];
    const interwikiLinksInfo = [[statistics['interwiki links removed'],
    I18n.t('metrics.interwiki_links_removed')]];
    const labelsInfo = [[statistics['labels changed'], I18n.t('metrics.labels_changed')],
    [statistics['labels removed'], I18n.t('metrics.labels_removed')]];
    const mergedInfo = [[statistics['merged to'], I18n.t('metrics.merged_to')]];
    const otherUpdatesInfo = [[statistics['qualifiers added'], I18n.t('metrics.qualifiers_added')],
    [statistics['redirects created'], I18n.t('metrics.redirects_created')],
    [statistics['restorations performed'], I18n.t('metrics.restorations_performed')],
    [statistics['reverts performed'], I18n.t('metrics.reverts_performed')],
    [statistics['no data'], I18n.t('metrics.no_data')],
    [statistics.unknown, I18n.t('metrics.unknown')]];

    return (
      <>
        <OverviewStat
          id="items-created"
          className={valueClass('items-created')}
          stat={statistics['items created']}
          statMsg={I18n.t('metrics.items_created')}
          renderZero={false}
          info={itemsInfo}
          infoId="items-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="claims-created"
          className={valueClass('claims-created')}
          stat={statistics['claims created']}
          statMsg={I18n.t('metrics.claims_created')}
          renderZero={false}
          info={claimsInfo}
          infoId="claims-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="aliases-added"
          className={valueClass('aliases-added')}
          stat={statistics['aliases added']}
          statMsg={I18n.t('metrics.aliases_added')}
          renderZero={false}
          info={aliasesInfo}
          infoId="aliases-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="descriptions-added"
          className={valueClass('descriptions-added')}
          stat={statistics['descriptions added']}
          statMsg={I18n.t('metrics.descriptions_added')}
          renderZero={false}
          info={descriptionsInfo}
          infoId="descriptions-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="interwiki-links-added"
          className={valueClass('interwiki-links-added')}
          stat={statistics['interwiki links added']}
          statMsg={I18n.t('metrics.interwiki_links_added')}
          renderZero={false}
          info={interwikiLinksInfo}
          infoId="interwiki-links-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="labels-added"
          className={valueClass('labels-added')}
          stat={statistics['labels added']}
          statMsg={I18n.t('metrics.labels_added')}
          renderZero={false}
          info={labelsInfo}
          infoId="labels-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="merged-from"
          className={valueClass('merged-from')}
          stat={statistics['merged from']}
          statMsg={I18n.t('metrics.merged_from')}
          renderZero={false}
          info={mergedInfo}
          infoId="merged-info"
          renderZeroInfo={false}
        />
        <OverviewStat
          id="other-updates"
          className={valueClass('other-updates')}
          stat={statistics['other updates']}
          statMsg={I18n.t('metrics.other_updates')}
          renderZero={true}
          info={otherUpdatesInfo}
          infoId="other-updates-info"
          renderZeroInfo={false}
        />
      </>
    );
};

WikidataOverviewStats.propTypes = {
  statistics: PropTypes.object,
  valueClass: PropTypes.func,
};

  export default WikidataOverviewStats;
