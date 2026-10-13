import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../utils/article_utils';
import { Link } from 'react-router-dom';

const StudentStats = ({ username, stats, maxProject }) => {
  const encodedUsername = encodeURIComponent(username);
  const metricRows = [
    {
      label: I18n.t(`${stats.course_string_prefix}.courses_enrolled`),
      value: stats.individual_courses_count,
      link: `/users/${encodedUsername}/course-details`
    },
    {
      label: I18n.t('metrics.word_count'),
      value: stats.individual_word_count,
      link: `/users/${encodedUsername}/stats/words`
    },
    {
      label: I18n.t('metrics.references_count'),
      value: stats.individual_references_count,
      link: `/users/${encodedUsername}/stats/references`
    },
    {
      label: I18n.t(`metrics.${ArticleUtils.projectSuffix(maxProject, 'articles_edited')}`),
      value: stats.individual_article_count,
      link: `/users/${encodedUsername}/stats/articles`
    },
    {
      label: I18n.t('metrics.upload_count'),
      value: stats.individual_upload_count,
      link: `/users/${encodedUsername}/uploads`
    }
  ];

  return (
    <div className="user_stats">
      <h3 className="user_stats__title">{I18n.t('user_profiles.student_impact', { username })}</h3>
      <div className="user-stats-table__wrap">
        <table className="user-stats-table">
          <thead>
            <tr>
              <th>{I18n.t('user_profiles.column_metric')}</th>
              <th>{I18n.t('user_profiles.column_value')}</th>
              <th>{I18n.t('user_profiles.column_details')}</th>
            </tr>
          </thead>
          <tbody>
            {metricRows.map(row => (
              <tr key={row.label}>
                <td className="user-stats-table__metric">{row.label}</td>
                <td className="user-stats-table__value">
                  <span>{row.value}</span>
                </td>
                <td className="user-stats-table__action">
                  <div className="user-stats-table__action-inner">
                    <Link to={row.link} className="button border ghost small">
                      {I18n.t('user_profiles.see_more')}
                    </Link>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

StudentStats.propTypes = {
  username: PropTypes.string,
  stats: PropTypes.object,
  maxProject: PropTypes.string
};

export default StudentStats;
