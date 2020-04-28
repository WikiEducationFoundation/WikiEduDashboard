import React from 'react';
import createReactClass from 'create-react-class';
import _ from 'lodash';

import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';

import { fetchStates, ASSIGNED_ROLE, STUDENT_ROLE } from '../../constants';
import { PageAssessmentGrades, ORESSupportedWiki, PageAssessmentSupportedWiki } from '../../utils/article_finder_language_mappings.js';

const ArticleFinderRow = createReactClass({
  getInitialState() {
    return {
      isLoading: false,
    };
  },

  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.state.isLoading && (this.props.assignment !== nextProps.assignment)) {
      this.setState({
        isLoading: false,
      });
    }
  },

  assignArticle(userId = null) {
    const assignment = {
      title: decodeURIComponent(this.props.title).trim(),
      project: this.props.home_wiki.project,
      language: this.props.home_wiki.language,
      course_slug: this.props.courseSlug,
      user_id: userId,
      role: ASSIGNED_ROLE,
    };
    this.setState({
      isLoading: true,
    });
    return this.props.addAssignment(assignment);
  },

  unassignArticle(userId = null) {
    const assignment = {
      article_title: decodeURIComponent(this.props.title).trim(),
      project: this.props.assignment.project,
      language: this.props.assignment.language,
      course_slug: this.props.courseSlug,
      role: ASSIGNED_ROLE,
      id: this.props.assignment.id,
      assignment_id: this.props.assignment.assignment_id,
      user_id: userId,
    };
    this.setState({
      isLoading: true,
    });
    return this.props.deleteAssignment(assignment);
  },

  render() {
    let pageviews;
    if (this.props.article.fetchState === 'REVISIONSCORE_RECEIVED') {
      pageviews = (<div className="results-loading"> &nbsp; &nbsp; </div>);
    }
    if (this.props.article.pageviews) {
      pageviews = Math.round(this.props.article.pageviews);
    } else if (this.props.article.fetchState === 'PAGEVIEWS_RECEIVED') {
      pageviews = (<div>Page Views not found!</div>);
    }

    let revScore;
    if (_.includes(ORESSupportedWiki.languages, this.props.home_wiki.language) && _.includes(ORESSupportedWiki.projects, this.props.home_wiki.project)) {
      if (this.props.article.fetchState === 'PAGEASSESSMENT_RECEIVED' || this.props.article.fetchState === 'REVISION_RECEIVED') {
        revScore = (<td><div className="results-loading"> &nbsp; &nbsp; </div></td>);
      } else if (this.props.article.revScore) {
        revScore = (<td className="revScore">{Math.round(this.props.article.revScore)}</td>);
      } else if (fetchStates[this.props.article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED) {
        revScore = (<td><div>Estimation Score not found!</div></td>);
      } else {
        revScore = (<td />);
      }
    }

    let grade;
    if (PageAssessmentSupportedWiki[this.props.home_wiki.project] && _.includes(PageAssessmentSupportedWiki[this.props.home_wiki.project], this.props.home_wiki.language)) {
      if (this.props.article.fetchState === 'TITLE_RECEIVED') {
        grade = (<td><div className="results-loading"> &nbsp; &nbsp; </div></td>);
      } else if (this.props.article.grade) {
        const gradeClass = `rating ${PageAssessmentGrades[this.props.home_wiki.project][this.props.home_wiki.language][this.props.article.grade].class}`;
        grade = (
          <td className="tooltip-trigger">
            <div className={gradeClass}><p>{PageAssessmentGrades[this.props.home_wiki.project][this.props.home_wiki.language][this.props.article.grade].pretty || '-'}</p></div>
            <div className="tooltip dark">
              <p>{I18n.t(`articles.rating_docs.${PageAssessmentGrades[this.props.home_wiki.project][this.props.home_wiki.language][this.props.article.grade].class || '?'}`, { class: this.props.article.grade || '' })}</p>
            </div>
          </td>
        );
      } else if (fetchStates[this.props.article.fetchState] >= fetchStates.PAGEASSESSMENT_RECEIVED) {
        grade = (
          <td className="tooltip-trigger">
            <div className="rating null"><p>-</p></div>
            <div className="tooltip dark">
              <p>{I18n.t('articles.rating_docs.?')}</p>
            </div>
          </td>
        );
      } else {
        grade = (<td />);
      }
    }
    let button;
    if (this.props.courseSlug && this.props.current_user.isAdvancedRole) {
      if (this.props.assignment) {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : ''}`;
        button = (
          <td>
            <button className={className} onClick={() => this.unassignArticle()}>{I18n.t('article_finder.remove_article')}</button>
          </td>
        );
      } else {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={() => this.assignArticle()}>{I18n.t('article_finder.add_available_article')}</button>
          </td>
        );
      }
    } else if (this.props.courseSlug && this.props.current_user.role === STUDENT_ROLE) {
      if (this.props.assignment) {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : ''}`;
        button = (
          <td>
            <button className={className} onClick={() => this.unassignArticle(this.props.current_user.id)}>{I18n.t('article_finder.unassign_article_self')}</button>
          </td>
        );
      } else {
        const className = `button small add-available-article ${this.state.isLoading ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={() => this.assignArticle(this.props.current_user.id)}>{I18n.t('article_finder.assign_article_self')}</button>
          </td>
        );
      }
    }


    const article = {
      ...this.props.article,
      language: this.props.home_wiki.language,
      project: this.props.home_wiki.project,
      url: `https://${this.props.home_wiki.language}.${this.props.home_wiki.project}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`,
    };
    if (this.props.home_wiki.project === 'wikidata') {
      delete article.language;
      article.url = `https://${this.props.home_wiki.project}.org/wiki/${this.props.article.title.replace(/ /g, '_')}`;
    }

    const articleViewer = (
      <ArticleViewer
        article={article}
        course={this.props.course}
        current_user={this.props.current_user}
        title={this.props.article.title}
        showArticleFinder={true}
        showPermalink={false}
      />
    );

    return (
      <tr>
        <td>
          {this.props.article.relevanceIndex}
        </td>
        <td>
          <div className="horizontal-flex">
            {articleViewer}
          </div>
        </td>
        {grade}
        {revScore}
        <td className="pageviews">
          {pageviews}
        </td>
        {button}
      </tr>);
  }
});


export default ArticleFinderRow;
