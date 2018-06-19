import React from 'react';
import createReactClass from 'create-react-class';

import ArticleViewer from '../common/article_viewer.jsx';

import { fetchStates, ASSIGNED_ROLE } from "../../constants";
import { PageAssessmentGrades, ORESSupportedWiki, PageAssessmentSupportedWiki } from '../../utils/article_finder_language_mappings.js';

const ArticleFinderRow = createReactClass({
  getInitialState() {
    return {
      isLoading: false,
    };
  },

  componentWillReceiveProps(nextProps) {
    if (this.state.isLoading && (this.props.assignment !== nextProps.assignment)) {
      this.setState({
        isLoading: false,
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
      isLoading: true,
    });
    return this.props.addAssignment(assignment);
  },

  deleteAvailableArticle() {
    const assignment = {
      article_title: decodeURIComponent(this.props.title).trim(),
      project: this.props.assignment.project,
      language: this.props.assignment.language,
      course_id: this.props.courseSlug,
      role: ASSIGNED_ROLE,
      id: this.props.assignment.id,
    };
    this.setState({
      isLoading: true,
    });
    return this.props.deleteAssignment(assignment);
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
      else if (this.props.article.revScore) {
        revScore = (<td>{this.props.article.revScore}</td>);
      }
      else if (fetchStates[this.props.article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED) {
        revScore = (<td><div>Estimation Score not found!</div></td>);
      }
      else {
        revScore = (<td />);
      }
    }

    let grade;
    if (_.includes(PageAssessmentSupportedWiki.languages, this.props.course.home_wiki.language) && this.props.course.home_wiki.project === 'wikipedia') {
      if (this.props.article.fetchState === "TITLE_RECEIVED") {
        grade = (<td><div className="results-loading"> &nbsp; &nbsp; </div></td>);
      }
      else if (this.props.article.grade) {
        const gradeClass = `rating ${PageAssessmentGrades[this.props.course.home_wiki.language][this.props.article.grade].class}`;
        grade = (
          <td className="tooltip-trigger">
            <div className={gradeClass}><p>{PageAssessmentGrades[this.props.course.home_wiki.language][this.props.article.grade].pretty || '-'}</p></div>
            <div className="tooltip dark">
              <p>{I18n.t(`articles.rating_docs.${PageAssessmentGrades[this.props.course.home_wiki.language][this.props.article.grade].class || '?'}`, { class: this.props.article.grade || '' })}</p>
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
      else {
        grade = (<td />);
      }
    }
    let button;
    if (this.props.courseSlug) {
      if (this.props.assignment) {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : ''}`;
        button = (
          <td>
            <button className={className} onClick={this.deleteAvailableArticle}>{I18n.t('article_finder.remove_article')}</button>
          </td>
        );
      }
      else {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={this.addAvailableArticle}>{I18n.t('article_finder.add_available_article')}</button>
          </td>
          );
      }
    }

    const article = {
      ...this.props.article,
      language: this.props.course.home_wiki.language,
      project: this.props.course.home_wiki.project,
      url: `https://${this.props.course.home_wiki.language}.${this.props.course.home_wiki.project}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`,
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
            <a href={`https://${this.props.course.home_wiki.language}.${this.props.course.home_wiki.project}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`} className="inline" target="_blank">{this.props.title}</a>
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
