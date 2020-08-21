import React from 'react';
import moment from 'moment';

const StatisticsUpdateModal = (props) => {
    const course = props.course;
    const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');
    const updatesEndMoment = moment.utc(course.update_until);
    const futureUpdatesRemaining = updatesEndMoment.isAfter();
    const futureUpdatesMessage = futureUpdatesRemaining ? I18n.t('metrics.future_updates_remaining.true', { date: updatesEndMoment.format('MMMM Do YYYY') }) : I18n.t('metrics.future_updates_remaining.false');
    const additionalUpdateMessage = course.needs_update ? I18n.t('metrics.non_updating_course_update') : '';

    let lastUpdateSummary = '';
    const errorCount = course.updates.last_update.error_count;

    if (errorCount === 0) {
      lastUpdateSummary = `${I18n.t('metrics.last_update_success')}`;
    } else if (errorCount > 0) {
      lastUpdateSummary = `${I18n.t('metrics.error_count_message', { error_count: errorCount })}`;
    } else if (course.updates.last_update.orphan_lock_failure) {
      lastUpdateSummary = `${I18n.t('metrics.last_update_failed')}`;
    }

    const updateLogs = Object.values(course.flags.update_logs);
    const failureUpdatesCount = updateLogs.filter(log => log.orphan_lock_failure !== undefined).length;
    const erroredUpdatesCount = updateLogs.filter(log => log.error_count !== undefined && log.error_count > 0).length;
    const recentUpdatesSummary = I18n.t('metrics.recent_updates_summary', { total: updateLogs.length, failure_count: failureUpdatesCount, error_count: erroredUpdatesCount });

    // Update numbers (ids) are stored incrementally as counts in update_logs, so the
    // last update number is the total number of updates till now
    const updateNumbers = Object.keys(course.flags.update_logs);
    const totalUpdatesMessage = `${I18n.t('metrics.total_updates')}: ${updateNumbers[updateNumbers.length - 1]}`;

    const updateTimesInformation = props.getUpdateTimesInformation();

    return (
      <div className="statistics-update-modal-container">
        <div className="statistics-update-modal">
          <b>{I18n.t('metrics.update_status_heading')}</b>
          <br/>
          { lastUpdateSummary }
          <ul>
            <li>{ recentUpdatesSummary }</li>
            <li>{ totalUpdatesMessage }</li>
            { (updateTimesInformation !== null && futureUpdatesRemaining) && <li>{updateTimesInformation[1]}</li> }
            <li>{futureUpdatesMessage} {additionalUpdateMessage}</li>
          </ul>
          <b>{I18n.t('metrics.missing_data_heading')}</b>
          <br/>
          { I18n.t('metrics.missing_data_info') }:
          <ul>
            <li>{ I18n.t('metrics.replag_info') }<a href="https://replag.toolforge.org/" target="_blank">{I18n.t('metrics.replag_link')}</a></li>
            { course.type === 'ArticleScopedProgram' && <li>{ I18n.t('metrics.article_scoped_program_info') }</li> }
          </ul>
          <small>{ helpMessage }</small>
          <br/>
          <button className="button dark" onClick={props.toggleModal}>{I18n.t('metrics.close_modal')}</button>
        </div>
      </div>
    );
};

export default StatisticsUpdateModal;
