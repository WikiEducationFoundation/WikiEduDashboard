import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const CourseStats = React.createClass({
  displayName: 'CourseStats',

  propTypes: {
    course: React.PropTypes.object
  },

  render() {
    if (this.props.course.upload_usages_count === undefined) {
      return <div className="stat-display"></div>;
    }

    return (
      <div className="stat-display">
        <div className="stat-display__stat" id="articles-created">
          <div className="stat-display__value">{this.props.course.created_count}</div>
          <small>{I18n.t('metrics.articles_created')}</small>
        </div>
        <div className="stat-display__stat" id="articles-edited">
          <div className="stat-display__value">{this.props.course.edited_count}</div>
          <small>{I18n.t('metrics.articles_edited')}</small>
        </div>
        <div className="stat-display__stat" id="total-edits">
          <div className="stat-display__value">{this.props.course.edit_count}</div>
          <small>{I18n.t('metrics.edit_count_description')}</small>
        </div>
        <div className="stat-display__stat tooltip-trigger" id="student-editors">
          <div className="stat-display__value">{this.props.course.student_count}</div>
          <small>{CourseUtils.i18n('student_editors', this.props.course.string_prefix)}</small>
          <div className="tooltip dark" id="trained-count">
            <h4 className="stat-display__value">{this.props.course.trained_count}</h4>
            <p>{I18n.t('metrics.are_trained')}</p>
          </div>
        </div>
        <div className="stat-display__stat" id="word-count">
          <div className="stat-display__value">{this.props.course.word_count}</div>
          <small>{I18n.t('metrics.word_count')}</small>
        </div>
        <div className="stat-display__stat" id="view-count">
          <div className="stat-display__value">{this.props.course.view_count}</div>
          <small>{I18n.t('metrics.view_count_description')}</small>
        </div>
        <div className="stat-display__stat tooltip-trigger" id="upload-count">
          <div className="stat-display__value">{this.props.course.upload_count}</div>
          <small>{I18n.t('metrics.upload_count')}</small>
          <div className="tooltip dark" id="upload-usage">
            <h4 className="stat-display__value">{this.props.course.upload_usages_count}</h4>
            <p>{I18n.t('metrics.uploads_in_use_count', { count: this.props.course.upload_usages_count })}</p>
            <h4 className="stat-display__value">{this.props.course.upload_usages_count}</h4>
            // <p>{I18n.t('metrics.upload_usages_count', { count: this.props.course.upload_usages_count })}</p>
          </div>
        </div>
      </div>
    );
  }
});

export default CourseStats;
