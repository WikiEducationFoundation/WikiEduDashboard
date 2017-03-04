import React from 'react';

const ContributionStats = React.createClass({
  render() {
    return (
      <div>
        <h5>
          Total Impact made by Itachi &#10092;  As an Instructor -- As a student -- By his/her students &#10093;
        </h5>
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

export default ContributionStats;
