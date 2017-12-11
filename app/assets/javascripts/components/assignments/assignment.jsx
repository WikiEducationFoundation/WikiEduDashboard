import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import CourseUtils from '../../utils/course_utils.js';
import Feedback from '../common/feedback.jsx';

const userLink = (wiki, assignment) => {
  if (!wiki) {
    return <div key={`assignment_${assignment.id}`}>{assignment.username}</div>;
  }
  const link = `https://${wiki.language}.${wiki.project}.org/wiki/User:${assignment.username}`;
  return <a key={`assignment_${assignment.id}`} href={link}>{assignment.username}</a>;
};

const Assignment = createReactClass({
  displayName: 'Assignment',
  propTypes: {
    article: PropTypes.object,
    assignmentGroup: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object
  },
  render() {
    if (!this.props.course.home_wiki) { return <div />; }
    const article = this.props.article || CourseUtils.articleFromAssignment(this.props.assignmentGroup[0], this.props.course.home_wiki);
    if (!article.formatted_title) {
      article.formatted_title = CourseUtils.formattedArticleTitle(article, this.props.course.home_wiki);
    }
    const className = 'assignment';
    const ratingClass = `rating ${article.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const articleLink = <a onClick={this.stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;
    const assignees = [];
    const reviewers = [];
    const iterable = _.sortBy(this.props.assignmentGroup, 'username');
    for (let i = 0; i < iterable.length; i++) {
      const assignment = iterable[i];
      if (assignment.role === 0 && assignment.user_id && assignment.username) {
        const usernameLink = userLink(this.props.course.home_wiki, assignment);
        assignees.push(usernameLink);
        assignees.push(', ');
      } else if (assignment.role === 1 && assignment.user_id && assignment.username) {
        const usernameLink = userLink(this.props.course.home_wiki, assignment);
        reviewers.push(usernameLink);
        reviewers.push(', ');
      }
    }

    if (assignees.length) { assignees.pop(); }
    if (reviewers.length) { reviewers.pop(); }

    let feedback;
    // If the article exists (and therefore has an article id) then shows Feedback
    // If the article doesn't exist, then Feedback is based on a user's sandbox only if a single user is assigned
    if (this.props.assignmentGroup.length === 1 || this.props.assignmentGroup[0].article_id) {
      feedback = <Feedback assignment={this.props.assignmentGroup[0]} username={this.props.assignmentGroup[0].username} current_user={this.props.current_user} />;
    }

    return (
      <tr className={className}>
        <td className="tooltip-trigger desktop-only-tc">
          <p className="rating_num hidden">{article.rating_num}</p>
          <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${article.rating || '?'}`)}</p>
          </div>
        </td>
        <td>
          <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>
          <p className="title">
            {articleLink}
          </p>
        </td>
        <td className="desktop-only-tc">{assignees}</td>
        <td className="desktop-only-tc">{reviewers}</td>
        <td>{feedback}</td>
      </tr>
    );
  }
}
);

export default Assignment;
