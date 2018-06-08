import React from 'react';
import createReactClass from 'create-react-class';

import ArticleViewer from '../common/article_viewer.jsx';

import { fetchStates, ASSIGNED_ROLE, ORESSupportedWiki } from "../../constants";

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
      role: ASSIGNED_ROLE,
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
    if (_.includes(ORESSupportedWiki.languages, this.props.course.home_wiki.language) && this.props.course.home_wiki.project === 'wikipedia') {
      if (this.props.article.fetchState === "PAGEASSESSMENT_RECEIVED" || this.props.article.fetchState === "REVISION_RECEIVED") {
       revScore = (<td><div className="results-loading"> &nbsp; &nbsp; </div></td>);
      }
      if (this.props.article.revScore) {
        revScore = (<td>{this.props.article.revScore}</td>);
      }
      else if (fetchStates[this.props.article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED) {
        revScore = (<td><div>Estimation Score not found!</div></td>);
      }
    }

    const prettyGrades = {
      Start: 's',
      Stub: 's',
      B: 'b',
      C: 'c',
      GA: 'ga',
      FA: 'fa',
    };
    let grade;
    if (this.props.article.fetchState === "TITLE_RECEIVED") {
      grade = (<td><div className="results-loading"> &nbsp; &nbsp; </div></td>);
    }
    if (this.props.article.grade) {
      const gradeClass = `rating ${this.props.article.grade.toLowerCase()}`;
      grade = (
        <td className="tooltip-trigger">
          <div className={gradeClass}><p>{prettyGrades[this.props.article.grade] || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${this.props.article.grade.toLowerCase() || '?'}`)}</p>
          </div>
        </td>
        );
    }
    else if (fetchStates[this.props.article.fetchState] >= fetchStates.PAGEASSESSMENT_RECEIVED) {
      grade = (
        <td className="tooltip-trigger">
          <div className="rating null"><p>-</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.?`)}</p>
          </div>
        </td>
        );
    }
    let button;
    if (this.props.courseSlug) {
      if (this.props.isAdded) {
        button = (
          <td>
            <button className="button small disabled add-available-article">{I18n.t('article_finder.already_added')}</button>
          </td>
        );
      }
      else {
        const className = `button small add-available-article ${this.state.isAdding ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={this.addAvailableArticle}>{I18n.t('article_finder.add_available_article')}</button>
          </td>
          );
      }
    }

    const article = {
      ...this.props.article,
      language: 'en',
      project: 'wikipedia',
      url: `https://${'en'}.${'wikipedia'}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`,
    };
    const articleViewer = (
      <ArticleViewer
        article={article}
        showButtonClass="pull-left"
        showArticleFinder={true}
      />
    );

    return (
      <tr>
        <td>
          <div className="horizontal-flex">
            <a href={`https://${'en'}.${'wikipedia'}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`} className="inline" target="_blank">{this.props.title}</a>
            <div>
              {articleViewer}
            </div>
          </div>
        </td>
        {grade}
        {revScore}
        <td>
          {pageviews}
        </td>
        {button}
      </tr>);
  }
});


export default ArticleFinderRow;
