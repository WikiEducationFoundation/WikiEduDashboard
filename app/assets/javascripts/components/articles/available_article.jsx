import React from 'react';
import CourseUtils from '../../utils/course_utils.js';
import ServerActions from '../../actions/server_actions.js';
import AssignmentActions from '../../actions/assignment_actions.js';

const AvailableArticle = React.createClass({
  displayName: 'AvailableArticle',

  propTypes: {
    assignment: React.PropTypes.object,
    current_user: React.PropTypes.object,
    course: React.PropTypes.object
  },

  onSelectHandler(e) {
    e.preventDefault();

    const assignment = {
      id: this.props.assignment.id,
      user_id: this.props.current_user.id,
      role: 0
    };

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
    let actionButton;
    let className = 'assignment';
    const { assignment } = this.props;
    const article = CourseUtils.articleFromAssignment(assignment);
    let ratingClass = `rating ${assignment.article_rating}`;
    let ratingMobileClass = `${ratingClass} tablet-only`;
    let articleLink = <a onClick={this.stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;

    if (this.props.current_user.admin || this.props.current_user.role > 0) {
      actionButton = (
        <button className="button dark" onClick={this.onRemoveHandler}>{I18n.t('assignments.remove')}</button>
      );
    } else {
      actionButton = (
        <button className="button dark" onClick={this.onSelectHandler}>{I18n.t('assignments.select')}</button>
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

export default AvailableArticle;
