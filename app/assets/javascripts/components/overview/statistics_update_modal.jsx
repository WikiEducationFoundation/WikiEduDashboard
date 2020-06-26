import React from 'react';
import Modal from '../common/modal';

const StatisticsUpdateModal = (props) => {
    const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');

    const errorCount = props.course.updates.last_update.error_count;
    const errorMessage = errorCount > 0 ? `${I18n.t('metrics.error_count_message', { error_count: errorCount })} ` : '';

    // Update numbers (ids) are stored incrementally as counts in update_logs, so the
    // last update number is the total number of updates till now
    const updateNumbers = Object.keys(props.course.flags.update_logs);
    const totalUpdatesMessage = `${I18n.t('metrics.total_updates')}: ${updateNumbers[updateNumbers.length - 1]}`;

    let missingDataMessage;
    if (props.course.type === 'ArticleScopedProgram') {
      missingDataMessage = `${I18n.t('metrics.article_scoped_program_info')} ${I18n.t('metrics.replag_info')}`;
    } else {
      missingDataMessage = `${I18n.t('metrics.replag_info')}`;
    }

    return (
      <Modal modalClass="statistics-update-modal">
        <b>{I18n.t('metrics.update_status_heading')}</b>
        <br/>
        { errorMessage }
        <ul>
          <li>{ totalUpdatesMessage }</li>
          <li>{ props.nextUpdateMessage }</li>
        </ul>
        <b>{I18n.t('metrics.missing_data_heading')}</b>
        <br/>
        { missingDataMessage }
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
