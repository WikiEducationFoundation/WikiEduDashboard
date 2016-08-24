import React from 'react';
import AssignButton from './assign_button.cjsx';
import { trunc } from '../../utils/strings';
import CourseUtils from '../../utils/course_utils.js';

const AssignCell = React.createClass({
  propTypes: {
    assignments: React.PropTypes.array,
    prefix: React.PropTypes.string,
    current_user: React.PropTypes.object,
    student: React.PropTypes.object,
    editable: React.PropTypes.bool,
    role: React.PropTypes.number
  },

  displayname: 'AssignCell',

  stop(e) {
    return e.stopPropagation();
  },
  open(e) {
    return this.refs.button.open(e);
  },
  render() {
    let link;
    if (this.props.assignments.length > 0) {
      const article = CourseUtils.articleFromAssignment(this.props.assignments[0]);
      if (this.props.assignments.length > 1) {
        let articleCount = I18n.t('users.number_of_articles', { count: this.props.assignments.length });
        link = (
          <span onClick={this.open}>
            {this.props.prefix}
            {articleCount}
          </span>
        );
      } else {
        let titleText = trunc(article.formatted_title, 30);
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
    let permitted = isCurrentUser || (instructorOrAdmin && this.props.editable);

    return (
      <div>
        {link}
        <AssignButton {...this.props} role={this.props.role} permitted={permitted} ref="button" />
      </div>
    );
  }
}
);

export default AssignCell;
