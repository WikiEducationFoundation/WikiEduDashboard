import React from 'react';
import createReactClass from 'create-react-class';
import { fetchStates } from "../../constants";

const ArticleFinderRow = createReactClass({
  getInitialState() {
    return {
      isAdding: false,
    };
  },

  componentWillReceiveProps(nextProps) {
    if (this.state.isAdding && (this.props.isAdded !== nextProps.isAdded)) {
      this.setState({
        isAdding: false,
      });
    }
  },

  addAvailableArticle() {
    const assignment = {
      title: decodeURIComponent(this.props.title).trim(),
      project: this.props.course.home_wiki.project,
      language: this.props.course.home_wiki.language,
      course_id: this.props.courseSlug,
      user_id: null,
      role: 0,
    };
    this.setState({
      isAdding: true,
    });
    return this.props.addAssignment(assignment);
  },

  render() {
    let pageviews;
    if (this.props.article.fetchState === "REVISIONSCORE_RECEIVED") {
     pageviews = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.pageviews) {
      pageviews = this.props.article.pageviews;
    }
    else if (this.props.article.fetchState === "PAGEVIEWS_RECEIVED") {
      pageviews = (<div>Page Views not found!</div>);
    }

    let revScore;
    if (this.props.article.fetchState === "PAGEASSESSMENT_RECEIVED" || this.props.article.fetchState === "REVISION_RECEIVED") {
     revScore = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.revScore) {
      revScore = this.props.article.revScore;
    }
    else if (fetchStates[this.props.article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED) {
      revScore = (<div>Estimation Score not found!</div>);
    }

    let grade;
    if (this.props.article.fetchState === "TITLE_RECEIVED") {
      grade = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.grade) {
      grade = this.props.article.grade;
    }
    else if (fetchStates[this.props.article.fetchState] >= fetchStates.PAGEASSESSMENT_RECEIVED) {
      grade = (<div>Not rated</div>);
    }
    let button;
    if (this.props.courseSlug) {
      if (this.props.isAdded) {
        button = (
          <td>
            <button className="button small disabled">Already added to available articles</button>
          </td>
        );
      }
      else {
        const className = `button small add-available-article ${this.state.isAdding ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={this.addAvailableArticle}> Add as available article</button>
          </td>
          );
      }
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
        {button}
      </tr>);
  }
});


export default ArticleFinderRow;
