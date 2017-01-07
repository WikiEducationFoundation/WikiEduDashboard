import React from 'react';

const EnrollCard = React.createClass({
  displayName: 'EnrollCard',

  propTypes: {
    user: React.PropTypes.object,
    userRole: React.PropTypes.number,
    course: React.PropTypes.object,
    courseLink: React.PropTypes.string,
    passcode: React.PropTypes.string,
    enrolledParam: React.PropTypes.string,
    enrollFailureReason: React.PropTypes.string
  },

  render() {
    let messageBody;
    if (this.props.enrolledParam !== undefined) {
      // Enrollment is complete
      if (this.props.enrolledParam === 'true') {
        messageBody = (
          <div>
            <h1>{I18n.t('application.greeting2')}</h1>
            <p>{I18n.t('courses.join_successful', { title: this.props.course.title || '' })}</p>
          </div>
        );
      // Enrollment failed (not approved?)
      } else if (this.props.enrolledParam === 'false') {
        messageBody = (
          <div>
            <h1>{I18n.t('courses.join_failed')}</h1>
            <p>{I18n.t(`courses.join_failure_details.${this.props.enrollFailureReason}`)}</p>
          </div>
        );
      }
    // User is logged in and ready to enroll
    } else if (this.props.user.id && this.props.userRole === -1) {
      messageBody = (
        <div>
          <h1>{I18n.t('courses.join_prompt', { title: this.props.course.title || '' })}</h1>
          <a className="button dark" href={this.props.course.enroll_url + this.props.passcode}>{I18n.t('courses.join')}</a>
          <a className="button border" href={this.props.courseLink}>{I18n.t('application.cancel')}</a>
        </div>
      );
    // User is already enrolled
    } else if (this.props.userRole >= 0) {
      messageBody = <h1>{I18n.t('courses.already_enrolled', { title: this.props.course.title })}</h1>;
    // User is not logged in
    } else if (!this.props.user.id) {
      messageBody = (
        <div>
          <h1>{I18n.t('application.greeting')}</h1>
          <p>{I18n.t('courses.invitation', { title: this.props.course.title })}</p>
          <p>
            <a href={`/users/auth/mediawiki?origin=${window.location}`} className="button auth dark">
              <i className="icon icon-wiki-logo"></i> {I18n.t('application.log_in_extended')}
            </a>
            <a href={`/users/auth/mediawiki_signup?origin=${window.location}`} className="button auth signup border">
              <i className="icon icon-wiki-logo"></i> {I18n.t('application.sign_up_extended')}
            </a>
          </p>
        </div>
      );
    }

    const closeLink = (
      <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{ fill: 'currentcolor', verticalAlign: 'middle', width: '32px', height: '32px' }} >
        <g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g>
      </svg>
    );

    return (
      <div className="module enroll">
        <a href={this.props.courseLink}>
          {closeLink}
        </a>
        {messageBody}
      </div>
    );
  }
});

export default EnrollCard;
