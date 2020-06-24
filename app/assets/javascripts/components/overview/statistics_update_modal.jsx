import React from 'react';
import Modal from '../common/modal';

const StatisticsUpdateModal = (props) => {
    const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');

    return (
      <Modal modalClass="course-data-update-modal">
        <b>{I18n.t('metrics.update_status_heading')}</b>
        <br/>
        { props.errorMessage }
        <ul>
          <li>{ props.totalUpdatesMessage }</li>
          <li>{ props.nextUpdateMessage }</li>
        </ul>
        <b>{I18n.t('metrics.missing_data_heading')}</b>
        <br/>
        { props.missingDataMessage }
        <br/>
        <a href="https://replag.toolforge.org/" target="_blank">{I18n.t('metrics.replag_link')}</a>
        <br/>
        <small className="mt1">{ helpMessage }</small>
        <br/>
        <button className="button dark" onClick={props.toggleModal}>{I18n.t('metrics.close_modal')}</button>
      </Modal>
    );
};

export default StatisticsUpdateModal;
