import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const userLink = username => <a key={username} href="https://en.wikipedia.org/wiki/User:#{username}">{username}</a>;

const Assignment = React.createClass({
  displayName: 'Assignment',
  propTypes: {
    article: React.PropTypes.object,
    assign_group: React.PropTypes.array
  },
  render() {
    const article = this.props.article || CourseUtils.articleFromAssignment(this.props.assign_group[0]);

    if (!article.formatted_title) {
      article.formatted_title = CourseUtils.formattedArticleTitle(
        this.props.assign_group[0].language,
        this.props.assign_group[0].project,
        article.title
      );
    }

    let className = 'assignment';
    let ratingClass = `rating ${article.rating}`;
    let ratingMobileClass = `${ratingClass} tablet-only`;
    let articleLink = <a onClick={this.stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;

    let assignees = [];
    let reviewers = [];
    const iterable = _.sortBy(this.props.assign_group, 'username');
    for (let i = 0; i < iterable.length; i++) {
      const assignment = iterable[i];
      if (assignment.role === 0) {
        assignees.push(userLink(assignment.username));
        assignees.push(', ');
      } else if (assignment.role === 1) {
        reviewers.push(userLink(assignment.username));
        reviewers.push(', ');
      }
    }

    if (assignees.length) { assignees.pop(); }
    if (reviewers.length) { reviewers.pop(); }

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
        <td></td>
      </tr>
    );
  }
}
);

export default Assignment;
