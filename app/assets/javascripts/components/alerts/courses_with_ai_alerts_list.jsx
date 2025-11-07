import React, { useState } from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';

const CoursesWithAiAlertsList = ({ stats }) => {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  const courses = Object.values(stats);

  const sortedCourses = [...courses].sort((a, b) => {
    const { key, direction } = sortConfig;
    if (!key) return 0;
    const order = direction === 'asc' ? 1 : -1;
    return (a[key] - b[key]) * order;
  });

  const sortBy = (key) => {
    setSortConfig((prev) => {
      if (prev.key === key) {
        return { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' };
      }
      return { key, direction: 'asc' };
    });
  };

  const keys = {
    course2: {
      label: I18n.t('campaign.course'),
      sortable: false
    },
    mainspace_count: {
      label: I18n.t('alerts.ai_stats.alerts_in_mainspace'),
      order: sortConfig.key === 'mainspace_count' ? sortConfig.direction : ''
    },
    users_count: {
      label: I18n.t('alerts.ai_stats.users_involved'),
      order: sortConfig.key === 'users_count' ? sortConfig.direction : ''
    }
  };

  const elements = sortedCourses.map(data => (
    <tr key={data.course}>
      <td><a target="_blank" href={`/courses/${data.course_slug}`}>{data.course}</a></td>
      <td>{data.mainspace_count}</td>
      <td>{data.users_count}</td>
    </tr>
  ));

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="courses_with_ai_alerts"
      none_message={I18n.t('alerts.no_alerts')}
      sortable={true}
      sortBy={sortBy}
    />
  );
};

CoursesWithAiAlertsList.propTypes = {
  stats: PropTypes.array
};

export default CoursesWithAiAlertsList;
