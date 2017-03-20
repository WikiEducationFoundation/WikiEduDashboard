import React from 'react';
import ByStudentsStats from './by_students_stats.jsx';
import StudentStats from './student_stats.jsx';
import CoursesTaughtGraph from './courses_taught_graph.jsx';
import StudentsTaughtGraph from './students_taught_graph.jsx';

const InstructorStats = React.createClass({
  propTypes: {
    username: React.PropTypes.string,
    stats: React.PropTypes.object,
    isStudent: React.PropTypes.bool,
    statsGraphsData: React.PropTypes.object
  },

  getInitialState() {
    return {
      selectedGraph: 'courses_count'
    };
  },

  setCoursesCountGraph() {
    this.setState({
      selectedGraph: 'courses_count'
    });
  },

  setStudentsCountGraph() {
    this.setState({
      selectedGraph: 'students_count'
    });
  },

  render() {
    let asStudent;
    let statsVisualizations;
    if (this.state.selectedGraph === 'courses_count')
    {
      statsVisualizations = (
        <CoursesTaughtGraph
          statsData = {this.props.statsGraphsData.asinstructor_stats.courses_count}
        />
       );
    } else if (this.state.selectedGraph === 'students_count') {
      statsVisualizations = (
        <StudentsTaughtGraph
          statsData = {this.props.statsGraphsData.asinstructor_stats.students_count}
        />
       );
    }
    if (this.props.isStudent) {
      asStudent = (
        <StudentStats
          username = {this.props.username}
          stats = {this.props.stats.as_student}
        />
      );
    }
    return (
      <div className= "user_stats">
        <div id = "instructor-profile-stats">
          <h5>
            {I18n.t('user_profiles.instructor_impact', { username: this.props.username })}
          </h5>
          <div className= "stat-display">
            <div onClick={this.setCoursesCountGraph} className= "stat-display__stat button">
              <div className="stat-display__value">
                {this.props.stats.as_instructor.courses_count}
              </div>
              <small>
                {I18n.t(`${this.props.stats.as_instructor.course_string_prefix}.courses_taught`)}
              </small>
            </div>
            <div onClick={this.setStudentsCountGraph} className ="stat-display__stat tooltip-trigger button">
              <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
              <div className="stat-display__value">
                {this.props.stats.as_instructor.user_count}
              </div>
              <small>
                {I18n.t(`${this.props.stats.as_instructor.course_string_prefix}.students`)}
              </small>
              <div className="tooltip dark">
                <h4>
                  {this.props.stats.as_instructor.trained_percent}
                  \%
                </h4>
                <p>
                  {I18n.t("users.up_to_date_with_training")}
                </p>
              </div>
            </div>
          </div>
          {statsVisualizations}
        </div>
        < ByStudentsStats
          username = {this.props.username}
          stats = {this.props.stats.by_students}
        />
        {asStudent}
      </div>
    );
  }
});

export default InstructorStats;
