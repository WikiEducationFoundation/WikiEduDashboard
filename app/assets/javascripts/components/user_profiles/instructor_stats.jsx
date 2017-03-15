import React from 'react';
import ByStudents from './by_students.jsx';
import StudentStats from './student_stats.jsx';

const InstructorStats = React.createClass({
  propTypes: {
    username: React.PropTypes.string,
    stats: React.PropTypes.object,
    isstudent: React.PropTypes.bool
  },

  render() {
    let asStudent;

    if (this.props.isstudent) {
      asStudent = (
        <StudentStats
          username = {this.props.username}
          stats = {this.props.stats}
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
            <div className= "stat-display__stat">
              <div className="stat-display__value">
                {this.props.stats.courses_count}
              </div>
              <small>
                {I18n.t(`${this.props.stats.course_string_prefix}.courses_taught`)}
              </small>
            </div>
            <div className ="stat-display__stat tooltip-trigger">
              <div className="stat-display__value">
                {this.props.stats.user_count}
              </div>
              <small>
                {I18n.t(`${this.props.stats.course_string_prefix}.students`)}
              </small>
              <div className="tooltip dark">
                <h4>
                  {this.props.stats.trained_percent}
                  \%
                </h4>
                <p>
                  {I18n.t("users.up_to_date_with_training")}
                </p>
              </div>
            </div>
          </div>
        </div>
        < ByStudents
          username = {this.props.username}
          stats = {this.props.stats}
        />
        {asStudent}
      </div>
    );
  }
});

export default InstructorStats;
