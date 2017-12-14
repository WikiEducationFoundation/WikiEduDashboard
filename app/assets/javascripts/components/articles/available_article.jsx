import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";

import CourseUtils from '../../utils/course_utils.js';
import ServerActions from '../../actions/server_actions.js';
import AssignmentActions from '../../actions/assignment_actions.js';
import { addNotification } from '../../actions/notification_actions.js';

export const AvailableArticle = createReactClass({
  displayName: 'AvailableArticle',

  propTypes: {
    assignment: PropTypes.object,
    current_user: PropTypes.object,
    course: PropTypes.object,
    addNotification: PropTypes.func
  },

  onSelectHandler() {
    const assignment = {
      id: this.props.assignment.id,
      user_id: this.props.current_user.id,
      role: 0
    };

    const title = this.props.assignment.article_title;
    this.props.addNotification({
      message: I18n.t('assignments.article', { title }),
      closable: true,
      type: 'success'
    });

    return ServerActions.updateAssignment(assignment);
  },

  onRemoveHandler(e) {
    e.preventDefault();

    const assignment = {
      id: this.props.assignment.id,
      course_id: this.props.course.slug,
      language: this.props.assignment.language,
      project: this.props.assignment.project,
      article_title: this.props.assignment.article_title,
      role: 0
    };

    if (!confirm(I18n.t('assignments.confirm_deletion'))) { return; }
    AssignmentActions.deleteAssignment(assignment);
    return ServerActions.deleteAssignment(assignment);
  },

  render() {
    const className = 'assignment';
    const { assignment } = this.props;
    const article = CourseUtils.articleFromAssignment(assignment, this.props.course.home_wiki);
    const ratingClass = `rating ${assignment.article_rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const articleLink = <a onClick={this.stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;

    let actionButton;
    // Show 'Select' button to students
    if (this.props.current_user.role === 0) {
      actionButton = (
        <button className="button dark" onClick={this.onSelectHandler}>{I18n.t('assignments.select')}</button>
      );
    // Show 'Remove' button to admins and facilitators
    } else if (this.props.current_user.admin || this.props.current_user.role > 0) {
      actionButton = (
        <button className="button dark" onClick={this.onRemoveHandler}>{I18n.t('assignments.remove')}</button>
      );
    }

    return (
      <tr className={className}>
        <td className="tooltip-trigger desktop-only-tc">
          <p className="rating_num hidden">{article.rating_num}</p>
          <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${assignment.article_rating || '?'}`)}</p>
          </div>
        </td>
        <td>
          <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>
          <p className="title">
            {articleLink}
          </p>
        </td>
        <td className="table-action-cell">
          {actionButton}
        </td>
      </tr>
    );
  }
}
);

const mapDispatchToProps = { addNotification };

export default connect(null, mapDispatchToProps)(AvailableArticle);
