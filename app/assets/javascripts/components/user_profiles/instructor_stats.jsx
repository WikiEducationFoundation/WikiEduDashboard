import React from 'react';

const InstructorStats = React.createClass({
  render() {
    return (
      <div>
        <h5> InstructorStats by </h5>
        <div className= "user_stats">
          <div className= "stat-display">
            <div className= "stat-display__stat">
              <div className="stat-display__value">
                10
              </div>
              <small>
                {I18n.t("metrics.view_count_description")}
              </small>
            </div>
          </div>
        </div>
      </div>
    );
  }
});

export default InstructorStats;
