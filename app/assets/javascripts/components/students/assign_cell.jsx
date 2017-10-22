import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import AssignButton from './assign_button.jsx';
import { trunc } from '../../utils/strings';
import CourseUtils from '../../utils/course_utils.js';

const AssignCell = createReactClass({
  displayName: 'AssignCell',

  propTypes: {
    assignments: PropTypes.array,
    prefix: PropTypes.string,
    current_user: PropTypes.object,
    student: PropTypes.object,
    editable: PropTypes.bool,
    role: PropTypes.number,
    tooltip_message: PropTypes.string,
    course: PropTypes.object.isRequired,
  },

  stop(e) {
    return e.stopPropagation();
  },
  open(e) {
    return this.refs.button.open(e);
  },
  render() {
    let link;
    if (this.props.assignments.length > 0) {
      const article = CourseUtils.articleFromAssignment(this.props.assignments[0], this.props.course.home_wiki);
      if (this.props.assignments.length > 1) {
        const articleCount = I18n.t('users.number_of_articles', { count: this.props.assignments.length });
        link = (
          <span onClick={this.open}>
            {this.props.prefix}
            {articleCount}
          </span>
        );
      } else {
        const titleText = trunc(article.formatted_title, 30);
        if (article.url) {
          link = (
            <span>
              {this.props.prefix}
              <a onClick={this.stop} href={article.url} target="_blank">{titleText}</a>
            </span>
          );
        } else {
          link = <span>{this.props.prefix}{titleText}</span>;
        }
      }
    } else if (!this.props.current_user) {
      link = <span>{I18n.t('users.no_articles')}</span>;
    }

    let isCurrentUser;
    if (this.props.student) { isCurrentUser = this.props.current_user.id === this.props.student.id; }
    const instructorOrAdmin = this.props.current_user.role > 0 || this.props.current_user.admin;
    const permitted = isCurrentUser || (instructorOrAdmin && this.props.editable);

    return (
      <div className="inline-button-peer">
        {link}
        <AssignButton {...this.props} role={this.props.role} permitted={permitted} ref="button" />
      </div>
    );
  }
}
);

export default AssignCell;
