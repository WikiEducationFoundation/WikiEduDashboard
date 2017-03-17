import React from 'react';

const ByStudentsStats = React.createClass({

  propTypes: {
    username: React.PropTypes.string,
    stats: React.PropTypes.object
  },
  render() {
    return (
      <div>
        <h5>
          {I18n.t('user_profiles.instructors_student_impact', { username: this.props.username })}
        </h5>
        <div className= "stat-display">
          <div className= "stat-display__stat">
            <div className="stat-display__value">
              {this.props.stats.word_count}
            </div>
            <small>
              {I18n.t('metrics.word_count')}
            </small>
          </div>
          <div className= "stat-display__stat">
            <div className="stat-display__value">
              {this.props.stats.view_sum}
            </div>
            <small>
              {I18n.t('metrics.view_count_description')}
            </small>
          </div>
          <div className= "stat-display__stat">
            <div className="stat-display__value">
              {this.props.stats.article_count}
            </div>
            <small>
              {I18n.t('metrics.articles_edited')}
            </small>
          </div>
          <div className= "stat-display__stat">
            <div className="stat-display__value">
              {this.props.stats.new_article_count}
            </div>
            <small>
              {I18n.t('metrics.articles_created')}
            </small>
          </div>
          <div className ="stat-display__stat tooltip-trigger">
            <div className="stat-display__value">
              {this.props.stats.upload_count}
            </div>
            <small>
              {I18n.t('metrics.upload_count')}
            </small>
            <div className="tooltip dark">
              <h4>
                {this.props.stats.uploads_in_use_count}
              </h4>
              <p>
                {I18n.t("metrics.uploads_in_use_count", { count: this.props.stats.uploads_in_use_count })}
              </p>
              <h4>{this.props.stats.upload_usage_count}</h4>
              <p>
                {I18n.t("metrics.upload_usages_count", { count: this.props.stats.upload_usage_count })}
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }
});

export default ByStudentsStats;
