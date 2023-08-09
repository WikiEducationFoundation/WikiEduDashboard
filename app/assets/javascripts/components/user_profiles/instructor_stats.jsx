import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ByStudentsStats from './by_students_stats.jsx';
import StudentStats from './student_stats.jsx';
import CoursesTaughtGraph from './graphs/as_instructor_graphs/courses_taught_graph.jsx';
import StudentsTaughtGraph from './graphs/as_instructor_graphs/students_taught_graph.jsx';
import Loading from '../common/loading.jsx';

const InstructorStats = ({ username, stats, maxProject, statsGraphsData, graphWidth, graphHeight, isStudent }) => {
  const [selectedGraph, setSelectedGraph] = useState('courses_count');
  const [coursesGraph, setCoursesGraph] = useState(true);

  const setCoursesCountGraph = () => {
    setSelectedGraph('courses_count');
    setCoursesGraph(true);
  };

  const setStudentsCountGraph = () => {
    setSelectedGraph('students_count');
    setCoursesGraph(false);
  };

  let asStudent;
  let statsVisualizations;
  const byStudents = (
    <ByStudentsStats
      username={username}
      stats={stats.by_students}
      maxProject={maxProject}
    />
  );
  if (selectedGraph === 'courses_count') {
    if (statsGraphsData != null) {
      statsVisualizations = (
        <CoursesTaughtGraph
          statsData={statsGraphsData.instructor_stats}
          graphWidth={graphWidth}
          graphHeight={graphHeight}
          courseStringPrefix={stats.as_instructor.course_string_prefix}
        />
      );
    } else {
      statsVisualizations = <Loading />;
    }
  } else if (selectedGraph === 'students_count') {
    statsVisualizations = (
      <StudentsTaughtGraph
        statsData={statsGraphsData.student_count}
        graphWidth={graphWidth}
        graphHeight={graphHeight}
        courseStringPrefix={stats.as_instructor.course_string_prefix}
      />
    );
  }
  if (isStudent) {
    asStudent = (
      <StudentStats
        username={username}
        stats={stats.as_student}
        maxProject={maxProject}
      />
    );
  }
  return (
    <div className="user_stats">
      <div id="instructor-profile-stats">
        <h5>
          {I18n.t('user_profiles.instructor_impact', { username: username })}
        </h5>
        <div className="stat-display">
          <div onClick={setCoursesCountGraph} className={`stat-display__stat button${coursesGraph ? ' active-button' : ''}`}>
            <div className="stat-display__value">
              {stats.as_instructor.courses_count}
            </div>
            <small>
              {I18n.t(`${stats.as_instructor.course_string_prefix}.courses_taught`)}
            </small>
          </div>
          <div onClick={setStudentsCountGraph} className={`stat-display__stat tooltip-trigger button${coursesGraph ? '' : ' active-button'}`}>
            <div className="stat-display__value">
              {stats.as_instructor.user_count}
              <img src="/assets/images/info.svg" alt="tooltip default logo" />
            </div>
            <small>
              {I18n.t(`${stats.as_instructor.course_string_prefix}.students`)}
            </small>
            <div className="tooltip dark">
              <h4>
                {stats.as_instructor.trained_percent}
                %
              </h4>
              <p>
                {I18n.t('users.up_to_date_with_training')}
              </p>
            </div>
          </div>
        </div>
        <div id="visualizations">
          {statsVisualizations}
        </div>
      </div>
      {byStudents}
      {asStudent}
    </div>
  );
};

InstructorStats.propTypes = {
  username: PropTypes.string,
  stats: PropTypes.object,
  isStudent: PropTypes.bool,
  statsGraphsData: PropTypes.object,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  maxProject: PropTypes.string
};

export default InstructorStats;
