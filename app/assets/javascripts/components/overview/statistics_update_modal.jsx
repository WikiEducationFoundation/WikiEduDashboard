import React from 'react';

const StatisticsUpdateModal = (props) => {
    const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');

    let errorMessage = '';
    const errorCount = props.course.updates.last_update.error_count;
    if (errorCount && errorCount > 0) {
      errorMessage = `${I18n.t('metrics.error_count_message', { error_count: errorCount })}`;
    } else if (props.course.updates.last_update.orphan_lock_failure) {
      errorMessage = `${I18n.t('metrics.last_update_failed')}`;
    }

    // Update numbers (ids) are stored incrementally as counts in update_logs, so the
    // last update number is the total number of updates till now
    const updateNumbers = Object.keys(props.course.flags.update_logs);
    const totalUpdatesMessage = `${I18n.t('metrics.total_updates')}: ${updateNumbers[updateNumbers.length - 1]}`;

    const updateTimesInformation = props.getUpdateTimesInformation();

    return (
      <div className="statistics-update-modal-container">
        <div className="statistics-update-modal">
          <b>{I18n.t('metrics.update_status_heading')}</b>
          <br/>
          { errorMessage }
          <ul>
            <li>{ totalUpdatesMessage }</li>
            { updateTimesInformation !== null && <li>{updateTimesInformation[1]}</li> }
          </ul>
          <b>{I18n.t('metrics.missing_data_heading')}</b>
          <br/>
          { I18n.t('metrics.missing_data_info') }:
          <ul>
            <li>{ I18n.t('metrics.replag_info') }<a href="https://replag.toolforge.org/" target="_blank">{I18n.t('metrics.replag_link')}</a></li>
            { props.course.type === 'ArticleScopedProgram' && <li>{ I18n.t('metrics.article_scoped_program_info') }</li> }
          </ul>
          <small>{ helpMessage }</small>
          <br/>
          <button className="button dark" onClick={props.toggleModal}>{I18n.t('metrics.close_modal')}</button>
        </div>
      </div>
    );
};

export default StatisticsUpdateModal;
