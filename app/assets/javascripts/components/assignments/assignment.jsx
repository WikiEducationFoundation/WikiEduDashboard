import React from 'react';
import PropTypes from 'prop-types';
import { sortBy } from 'lodash-es';

import CourseUtils from '../../utils/course_utils.js';
import Feedback from '../common/feedback.jsx';

const userLink = (wiki, assignment) => {
  if (!wiki) {
    return <div key={`assignment_${assignment.id}`}>{assignment.username}</div>;
  }
  const link = `https://${wiki.language || 'www'}.${wiki.project}.org/wiki/User:${assignment.username}`;
  return <a key={`assignment_${assignment.id}`} href={link} target="_blank">{assignment.username}</a>;
};

const Assignment = (props) => {
    if (!props.course.home_wiki) { return <div />; }
    const article = props.article || CourseUtils.articleFromAssignment(props.assignmentGroup[0], props.course.home_wiki);
    if (!article.formatted_title) {
      article.formatted_title = CourseUtils.formattedArticleTitle(article, props.course.home_wiki, props.wikidataLabel);
    }
    const className = 'assignment';
    const ratingClass = `rating ${article.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const articleLink = <a onClick={stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;
    const assignees = [];
    const reviewers = [];
    const iterable = sortBy(props.assignmentGroup, 'username');
    const isWikipedia = article.project === 'wikipedia';
    for (let i = 0; i < iterable.length; i += 1) {
      const assignment = iterable[i];
      if (assignment.role === 0 && assignment.user_id && assignment.username) {
        const usernameLink = userLink(props.course.home_wiki, assignment);
        assignees.push(usernameLink);
        assignees.push(', ');
      } else if (assignment.role === 1 && assignment.user_id && assignment.username) {
        const usernameLink = userLink(props.course.home_wiki, assignment);
        reviewers.push(usernameLink);
        reviewers.push(', ');
      }
    }

    if (assignees.length) { assignees.pop(); }
    if (reviewers.length) { reviewers.pop(); }

    let feedback;

    // If the article exists (and therefore has an article id) then shows Feedback
    // If the article doesn't exist, then Feedback is based on a user's sandbox only if a single user is assigned
    if (props.course.type === 'ClassroomProgramCourse') {
      if (props.assignmentGroup.length === 1 || props.assignmentGroup[0].article_id) {
        feedback = <Feedback assignment={props.assignmentGroup[0]} username={props.assignmentGroup[0].username} current_user={props.current_user} />;
      }
    }

    return (
      <tr className={className}>
        <td className="tooltip-trigger desktop-only-tc">
          {isWikipedia && <p className="rating_num hidden">{article.rating_num}</p>}
          {isWikipedia && <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>}
          {isWikipedia && <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${article.rating || '?'}`, { class: article.rating || '' })}</p>
            {/* eslint-disable-next-line */}
          </div>}
        </td>
        <td>
          {isWikipedia && <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>}
          <p className="title">
            {articleLink}
          </p>
        </td>
        <td className="desktop-only-tc">{assignees}</td>
        <td className="desktop-only-tc">{reviewers}</td>
        <td>{feedback}</td>
      </tr>
    );
  };
  Assignment.displayName = 'Assignment';
  Assignment.propTypes = {
    article: PropTypes.object,
    assignmentGroup: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object,
    wikidataLabel: PropTypes.string
  };
export default Assignment;
