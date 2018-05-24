import React from 'react';
import createReactClass from 'create-react-class';

import { TITLE_RECEIVED, PAGEASSESSMENT_RECEIVED,
 REVISION_RECEIVED, REVISIONSCORE_RECEIVED, PAGEVIEWS_RECEICED } from "../../constants";

const ArticleFinderRow = createReactClass({
  render() {
    let pageviews;
    if (this.props.article.fetchState === REVISIONSCORE_RECEIVED) {
     pageviews = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.pageviews) {
      pageviews = this.props.article.pageviews;
    }
    else if (this.props.article.fetchState === PAGEVIEWS_RECEICED) {
      pageviews = (<div>Page Views not found!</div>);
    }

    let revScore;
    if (this.props.article.fetchState === PAGEASSESSMENT_RECEIVED || this.props.article.fetchState === REVISION_RECEIVED) {
     revScore = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.revScore) {
      revScore = this.props.article.revScore;
    }
    else if (this.props.article.fetchState >= REVISIONSCORE_RECEIVED) {
      revScore = (<div>Estimation Score not found!</div>);
    }

    let grade;
    if (this.props.article.fetchState === TITLE_RECEIVED) {
      grade = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.grade) {
      grade = this.props.article.grade;
    }
    else if (this.props.article.fetchState >= PAGEASSESSMENT_RECEIVED) {
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
