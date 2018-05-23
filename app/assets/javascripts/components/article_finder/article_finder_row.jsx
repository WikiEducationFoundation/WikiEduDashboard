import React from 'react';
import createReactClass from 'create-react-class';

const ArticleFinderRow = createReactClass({
  render() {
    let pageviews = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    if (this.props.article.pageviews) {
      pageviews = this.props.article.pageviews;
    }

    let revScore = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    if (this.props.article.revScore) {
      revScore = this.props.article.revScore;
    }

    let grade = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    if (this.props.article.grade) {
      grade = this.props.article.grade;
    }
    return (
      <tr>
        <td>
          {this.props.title}
        </td>
        <td>
          {pageviews}
        </td>
        <td>
          {revScore}
        </td>
        <td>
          {grade}
        </td>
      </tr>);
  }
});

export default ArticleFinderRow;
