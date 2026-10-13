import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../utils/article_utils';
import { Link } from 'react-router-dom';

const StudentStats = ({ username, stats, maxProject }) => {
  const metricRows = [
    {
      label: I18n.t(`${stats.course_string_prefix}.courses_enrolled`),
      value: stats.individual_courses_count,
      link: `/users/${username}/course-details`
    },
    {
      label: I18n.t('metrics.word_count'),
      value: stats.individual_word_count,
      link: `/users/${username}/stats/words`
    },
    {
      label: I18n.t('metrics.references_count'),
      value: stats.individual_references_count,
      link: `/users/${username}/stats/references`
    },
    {
      label: I18n.t(`metrics.${ArticleUtils.projectSuffix(maxProject, 'articles_edited')}`),
      value: stats.individual_article_count,
      link: `/users/${username}/stats/articles`
    },
    {
      label: I18n.t('metrics.upload_count'),
      value: stats.individual_upload_count,
      link: `/users/${username}/uploads`,
      helperValue: stats.individual_upload_usage_count,
      helperLabel: I18n.t('metrics.upload_usages_count', { count: stats.individual_upload_usage_count })
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
                  {/* Oculto a pedido: no mostrar "total usages across languages" debajo del conteo de uploads.
                  {row.helperValue !== undefined && (
                    <span className="user-stats-table__helper">
                      <strong>{row.helperValue}</strong>
                      <span>{row.helperLabel}</span>
                    </span>
                  )}
                  */}
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
