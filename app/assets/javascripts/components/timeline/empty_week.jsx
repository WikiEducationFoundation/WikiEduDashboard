import React from 'react';
import CourseLink from '../common/course_link.jsx';

const EmptyWeek = React.createClass({
  displayName: 'EmptyWeek',

  propTypes: {
    empty_timeline: React.PropTypes.bool,
    edit_permissions: React.PropTypes.bool,
    course: React.PropTypes.object,
    addWeek: React.PropTypes.func
  },

  render() {
    let week;
    if (this.props.empty_timeline && this.props.edit_permissions) {
      const wizardLink = `/courses/${this.props.course.slug}/timeline/wizard`;

      week = (
        <p className="week__no-activity__get-started">
          {I18n.t('timeline.empty_week_1')}&nbsp;
          <span className="empty-week-clickable" onClick={this.props.addWeek}>{I18n.t('timeline.empty_week_2')}</span>&nbsp;
          {I18n.t('timeline.empty_week_3')}&nbsp;
          <CourseLink to={wizardLink} className="empty-week-clickable">{I18n.t('timeline.empty_week_4')}</CourseLink>
        </p>);
    } else if (this.props.empty_timeline) {
      week = (
        <p className="week__no-activity__get-started">
          {I18n.t('timeline.no_timeline')}
        </p>);
    } else {
      week = (<h1 className="h3">{I18n.t('timeline.no_activity_this_week')}</h1>);
    }

    return (
      <div className="week__no-activity">
        {week}
      </div>
    );
  }
}
    );

export default EmptyWeek;
