import React from 'react';
import ArticleUtils from '../../utils/article_utils';
import { isAfter, format } from 'date-fns';
import { getUTCDate, toDate } from '../../utils/date_utils';
import { computeTrackingDescription } from '../../utils/statistic_update_info_utils';
import TrackingDescription from './tracking_description';
import UpdateLogs from './update_logs';

const StatisticsUpdateModal = (props) => {
  const course = props.course;
  const helpMessage = Features.wikiEd
    ? I18n.t('metrics.wiki_ed_help') : I18n.t('metrics.outreach_help');

  const updatesEndMoment = toDate(course.update_until);
  const futureUpdatesRemaining = isAfter(updatesEndMoment, new Date());

  const futureUpdatesMessage = futureUpdatesRemaining
    ? I18n.t('metrics.future_updates_remaining.updates_active', {
        date: format(getUTCDate(updatesEndMoment), 'MMMM do yyyy')
      })
    : I18n.t('metrics.future_updates_remaining.updates_inactive');

  const additionalUpdateMessage = course.needs_update
    ? I18n.t('metrics.non_updating_course_update')
    : '';

  const trackingDescription = computeTrackingDescription(course);

  return (
    <div className="statistics-update-modal-container">
      <div className="statistics-update-modal">
        <b>{I18n.t('metrics.update_status_heading')}</b>
        <br />

        <UpdateLogs
          course={course}
          isNextUpdateAfter={props.isNextUpdateAfter}
          nextUpdateMessage={props.nextUpdateMessage}
          futureUpdatesMessage={futureUpdatesMessage}
          additionalUpdateMessage={additionalUpdateMessage}
        />

        {/* Tracking Description */}
        {trackingDescription && (
          <>
            <b>
              {I18n.t('metrics.tracking_status_title', {
                defaultValue: 'Tracking Status'
              })}
            </b>
            <TrackingDescription trackingDescription={trackingDescription} />
          </>
        )}

        <b>{I18n.t('metrics.missing_data_heading')}</b>
        <br />
        {I18n.t('metrics.missing_data_info')}:
        <ul>
          <li>
            {I18n.t('metrics.replag_info')}{' '}
            <a
              href="https://replag.toolforge.org/"
              target="_blank"
              rel="noopener noreferrer"
            >
              {I18n.t('metrics.replag_link')}
            </a>
          </li>

          {course.type === 'ArticleScopedProgram' && (
            <li>
              {I18n.t(
                `metrics.${ArticleUtils.projectSuffix(
                  course.home_wiki.project,
                  'article_scoped_program_info'
                )}`
              )}
            </li>
          )}
        </ul>

        <small>{helpMessage}</small>
        <br />

        <button className="button dark" onClick={props.toggleModal}>
          {I18n.t('metrics.close_modal')}
        </button>
      </div>
    </div>
  );
};

export default StatisticsUpdateModal;
