import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import CourseUtils from '../../utils/course_utils.js';
import { deleteAssignment, claimAssignment } from '../../actions/assignment_actions.js';

export const AvailableArticle = createReactClass({
  displayName: 'AvailableArticle',

  propTypes: {
    assignment: PropTypes.object,
    current_user: PropTypes.object,
    course: PropTypes.object,
    deleteAssignment: PropTypes.func,
    claimAssignment: PropTypes.func,
    selectable: PropTypes.bool
  },

  onSelectHandler() {
    const assignment = {
      id: this.props.assignment.id,
      user_id: this.props.current_user.id,
      role: 0
    };

    const title = this.props.assignment.article_title;
    const successNotification = {
      message: I18n.t('assignments.article', { title }),
      closable: true,
      type: 'success'
    };

    return this.props.claimAssignment(assignment, successNotification);
  },

  onRemoveHandler(e) {
    e.preventDefault();

    const assignment = {
      id: this.props.assignment.id,
      course_slug: this.props.course.slug,
      language: this.props.assignment.language,
      project: this.props.assignment.project,
      article_title: this.props.assignment.article_title,
      role: 0
    };

    if (!confirm(I18n.t('assignments.confirm_deletion'))) { return; }
    return this.props.deleteAssignment(assignment);
  },

  render() {
    const className = 'assignment';
    const { assignment } = this.props;

    const article = CourseUtils.articleFromAssignment(assignment, this.props.course.home_wiki);
    const ratingClass = `rating ${assignment.article_rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const articleLink = (
      <a
        onClick={this.stop}
        href={article.url}
        target="_blank"
        className="inline"
        style={{
          color:
            assignment.article_rating === 'does_not_exist'
              ? '#dd3333'
              : '#3366cc',
        }}
      >
        {article.formatted_title}
      </a>
    );
    const isWikipedia = article.project === 'wikipedia';

    let actionSelect;
    let actionRemove;
    if (this.props.current_user.isStudent && this.props.selectable) {
      actionSelect = (
        <button className="button dark" onClick={this.onSelectHandler}>{I18n.t('assignments.select')}</button>
      );
    }

    if (this.props.current_user.isAdvancedRole) {
      actionRemove = (
        <button className="button dark" onClick={this.onRemoveHandler}>{I18n.t('assignments.remove')}</button>
      );
    }

    return (
      <tr className={className}>
        <td className="tooltip-trigger desktop-only-tc">
          {isWikipedia && <p className="rating_num hidden">{article.rating_num}</p>}
          {isWikipedia && <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>}
          {isWikipedia && <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${assignment.article_rating || '?'}`, { class: assignment.article_rating || '' })}</p>
            {/* eslint-disable-next-line */}
          </div>}
        </td>
        <td>
          {isWikipedia && <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>}
          <p className="title">
            {articleLink}
          </p>
        </td>
        <td className="table-action-cell">
          {actionSelect}
          {actionRemove}
        </td>
      </tr>
    );
  }
}
);

const mapDispatchToProps = {
  deleteAssignment,
  claimAssignment
};

export default connect(null, mapDispatchToProps)(AvailableArticle);
