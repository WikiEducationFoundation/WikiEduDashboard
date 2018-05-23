import React from 'react';
import createReactClass from 'create-react-class';

const ArticleFinderRow = createReactClass({
  render() {
    let pageviews;
    if (this.props.article.fetchState === 4) {
     pageviews = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.pageviews) {
      pageviews = this.props.article.pageviews;
    }
    else if (this.props.article.fetchState === 5) {
      pageviews = (<div>Page Views not found!</div>);
    }

    let revScore;
    if (this.props.article.fetchState === 2 || this.props.article.fetchState === 3) {
     revScore = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.revScore) {
      revScore = this.props.article.revScore;
    }
    else if (this.props.article.fetchState >= 4) {
      revScore = (<div>Estimation Score not found!</div>);
    }

    let grade;
    if (this.props.article.fetchState === 1) {
      grade = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.grade) {
      grade = this.props.article.grade;
    }
    else if (this.props.article.fetchState >= 2) {
      grade = (<div>Not rated</div>);
    }
    return (
      <tr>
        <td>
          {this.props.title}
        </td>
        <td>
          {grade}
        </td>
        <td>
          {revScore}
        </td>
        <td>
          {pageviews}
        </td>
      </tr>);
  }
});

export default ArticleFinderRow;
