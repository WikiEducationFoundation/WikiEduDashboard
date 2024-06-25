import React from 'react';
import { nextUpdateExpected, getLastUpdateSummary, getTotaUpdatesMessage, getUpdateLogs } from '../../utils/statistic_update_info_utils';
import ArticleUtils from '../../utils/article_utils';
import { isAfter, format } from 'date-fns';
import { getUTCDate, toDate } from '../../utils/date_utils';

const StatisticsUpdateModal = (props) => {
  const course = props.course;
  const helpMessage = Features.wikiEd ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');
  const updatesEndMoment = toDate(course.update_until);
  const futureUpdatesRemaining = isAfter(updatesEndMoment, new Date());
  const futureUpdatesMessage = futureUpdatesRemaining ? I18n.t('metrics.future_updates_remaining.updates_active', { date: format(getUTCDate(updatesEndMoment), 'MMMM do yyyy') }) : I18n.t('metrics.future_updates_remaining.updates_inactive');
  const additionalUpdateMessage = course.needs_update ? I18n.t('metrics.non_updating_course_update') : '';

  const lastUpdateSummary = getLastUpdateSummary(course);
  const updateLogs = getUpdateLogs(course);

  const failureUpdatesCount = updateLogs.filter(log => log.orphan_lock_failure !== undefined).length;
  const erroredUpdatesCount = updateLogs.filter(log => log.error_count !== undefined && log.error_count > 0).length;
  const recentUpdatesSummary = I18n.t('metrics.recent_updates_summary', { total: updateLogs.length, failure_count: failureUpdatesCount, error_count: erroredUpdatesCount });

  // Update numbers (ids) are stored incrementally as counts in update_logs, so the
  // last update number is the total number of updates till now

  const totalUpdatesMessage = getTotaUpdatesMessage(course);

  const isNextUpdateAfter = props.isNextUpdateAfter;
  let nextUpdateMessage = props.nextUpdateMessage;

  if (!isNextUpdateAfter) {
    nextUpdateMessage = I18n.t('metrics.late_update', { late_update_time: nextUpdateExpected(course) });
  }

  return (
    <div className="statistics-update-modal-container">
      <div className="statistics-update-modal">
        <b>{I18n.t('metrics.update_status_heading')}</b>
        <br/>
        { lastUpdateSummary }
        <ul>
          <li>{ recentUpdatesSummary }</li>
          <li>{ totalUpdatesMessage }</li>
          <li>{nextUpdateMessage}</li>
          <li>{futureUpdatesMessage} {additionalUpdateMessage}</li>
        </ul>
        <b>{I18n.t('metrics.missing_data_heading')}</b>
        <br/>
        { I18n.t('metrics.missing_data_info') }:
        <ul>
          <li>{ I18n.t('metrics.replag_info') } <a href="https://replag.toolforge.org/" target="_blank">{I18n.t('metrics.replag_link')}</a></li>
          { course.type === 'ArticleScopedProgram' && <li>{ I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'article_scoped_program_info')}`) }</li> }
        </ul>
        <small>{ helpMessage }</small>
        <br/>
        <button className="button dark" onClick={props.toggleModal}>{I18n.t('metrics.close_modal')}</button>
      </div>
    </div>
  );
};

export default StatisticsUpdateModal;
