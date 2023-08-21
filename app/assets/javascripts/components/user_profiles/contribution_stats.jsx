import React, { useState } from 'react';
import PropTypes from 'prop-types';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';

const ContributionStats = ({ params, stats, statsGraphsData }) => {
  const [isStudent] = useState(JSON.parse(document.querySelector('#react_root')?.dataset.isstudent));
  const [isInstructor] = useState(JSON.parse(document.querySelector('#react_root')?.dataset.isinstructor));

  let contriStats;
  const graphWidth = 800;
  const graphHeight = 250;
  if (isInstructor.instructor) {
    contriStats = (
      <InstructorStats
        username={params.username}
        stats={stats}
        isStudent={isStudent.student}
        statsGraphsData={statsGraphsData}
        graphWidth={graphWidth}
        graphHeight={graphHeight}
        maxProject={stats.max_project}
      />
    );
  } else if (isStudent.student) {
    contriStats = (
      <StudentStats
        username={params.username}
        stats={stats.as_student}
        statsGraphsData={statsGraphsData}
        graphWidth={graphWidth}
        graphHeight={graphHeight}
        maxProject={stats.max_project}
      />
    );
  }

  return (
    <div id="statistics">
      <h3>{I18n.t('users.contribution_statistics')}</h3>
      {contriStats}
    </div>
  );
};

ContributionStats.propTypes = {
  params: PropTypes.object,
  stats: PropTypes.object.isRequired
};

export default ContributionStats;
