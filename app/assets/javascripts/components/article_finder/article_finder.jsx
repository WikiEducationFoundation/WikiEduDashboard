import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import InputRange from 'react-input-range';

import TextInput from '../common/text_input.jsx';
import ArticleFinderRow from './article_finder_row.jsx';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../../utils/article_finder_language_mappings.js';
import { fetchCategoryResults, fetchKeywordResults, updateFields, sortArticleFinder } from '../../actions/article_finder_action.js';
import { fetchAssignments, addAssignment, deleteAssignment } from '../../actions/assignment_actions.js';
import { getFilteredArticleFinder } from '../../selectors';

const ArticleFinder = createReactClass({
  getDefaultProps() {
    return {
      course: {
        home_wiki: {
          language: 'en',
          project: 'wikipedia'
        }
      }
    };
  },

  getInitialState() {
    return {
      isSubmitted: false,
      showFilters: false,
    };
  },

  componentWillMount() {
    if (this.props.course_id && this.props.loadingAssignments) {
      this.props.fetchAssignments(this.props.course_id);
    }
    return this.updateFields('home_wiki', this.props.course.home_wiki);
  },

  onKeyDown(keyCode, ref) {
    if (keyCode === 13) {
      ref.blur();
      this.searchArticles();
    }
  },

  updateFields(key, value) {
    return this.props.updateFields(key, value);
  },

  toggleFilter() {
    return this.setState({
      showFilters: !this.state.showFilters
    });
  },

  searchArticles() {
    this.setState({
      isSubmitted: true,
    });
    if (this.props.search_type === 'keyword') {
      return this.props.fetchKeywordResults(this.props.search_term, this.props.course);
    }
    return this.props.fetchCategoryResults(this.props.search_term, this.props.course);
  },

  fetchMoreResults() {
    if (this.props.search_type === 'keyword') {
      return this.props.fetchKeywordResults(this.props.search_term, this.props.course, this.props.offset, true);
    }
    return this.props.fetchCategoryResults(this.props.search_term, this.props.course, this.props.cmcontinue, true);
  },

  handleChange(e) {
    const grade = e.target.value;
    return this.props.updateFields("grade", grade);
  },

  render() {
    const searchTerm = (
      <TextInput
        id="category"
        onChange={this.updateFields}
        value={this.props.search_term}
        value_key="search_term"
        required
        editable
        label={I18n.t('article_finder.search')}
        placeholder={I18n.t('article_finder.search_placeholder')}
        onKeyDown={this.onKeyDown}
        ref="searchbox"
      />);

    const searchType = (
      <div className="search-type">
        <div>
          <label>
            <input type="radio" value="keyword" checked={this.props.search_type === "keyword"} onChange={(e) => this.updateFields("search_type", e.target.value)} />
            {I18n.t('article_finder.keyword_search')}
          </label>
        </div>
        <div>
          <label>
            <input type="radio" value="category" checked={this.props.search_type === "category"} onChange={(e) => this.updateFields("search_type", e.target.value)} />
            {I18n.t('article_finder.category_search')}
          </label>
        </div>
      </div>
      );

    const minimumViews = (
      <TextInput
        id="min_views"
        onChange={this.updateFields}
        value={this.props.min_views}
        value_key="min_views"
        required
        editable
        label={I18n.t('article_finder.minimum_views_label')}
        placeholder={I18n.t('article_finder.minimum_views_label')}
      />);

    const articleQuality = (
      <div className="form-group range-container">
        <label className="mb2">{I18n.t('article_finder.article_quality')}</label>
        <InputRange
          maxValue={100}
          minValue={0}
          value={this.props.article_quality}
          onChange={value => this.updateFields('article_quality', value)}
          step={1}
        />
      </div>
      );
    let filters;
    if (this.state.showFilters) {
      filters = (
        <div className="filters">
          {minimumViews}
          {articleQuality}
        </div>
      );
    }

    let filterButton;
    if (!this.state.showFilters) {
      filterButton = (
        <button className="button dark" onClick={this.toggleFilter}>{I18n.t('article_finder.show_filters')}</button>
      );
    }
    else {
      filterButton = (
        <button className="button" onClick={this.toggleFilter}>{I18n.t('article_finder.hide_filters')}</button>
      );
    }

    let filterBlock;
    if (this.state.isSubmitted && !this.props.loading) {
      filterBlock = (
        <div className="filter-block">
          {filterButton}
          {filters}
        </div>
      );
    }

    const keys = {
      title: {
        label: I18n.t('articles.title'),
        desktop_only: false
      },
      grade: {
        label: I18n.t('article_finder.page_assessment_class'),
        desktop_only: false,
        sortable: true,
      },
      revScore: {
        label: I18n.t('article_finder.completeness_estimate'),
        desktop_only: false,
        sortable: true,
      },
      pageviews: {
        label: I18n.t('article_finder.average_views'),
        desktop_only: false,
        sortable: true,
      },
      tools: {
        label: I18n.t('article_finder.tools'),
        desktop_only: false,
        sortable: false,
      }
    };
    if (this.props.sort.key) {
      const order = (this.props.sort.sortKey) ? 'asc' : 'desc';
      keys[this.props.sort.key].order = order;
    }
    if (!_.includes(ORESSupportedWiki.languages, this.props.course.home_wiki.language) || !this.props.course.home_wiki.project === 'wikipedia') {
      delete keys.revScore;
    }

    if (!_.includes(PageAssessmentSupportedWiki.languages, this.props.course.home_wiki.language) || !this.props.course.home_wiki.project === 'wikipedia') {
      delete keys.grade;
    }

    if (!this.props.course_id) {
      delete keys.tools;
    }

    let list;
    if (this.state.isSubmitted && !this.props.loading) {
      const elements = _.map(this.props.articles, (article, title) => {
        const assignment = _.find(this.props.assignments, { article_title: title });
        return (
          <ArticleFinderRow
            article={article}
            title={title}
            key={article.pageid}
            courseSlug={this.props.course_id}
            course={this.props.course}
            assignment={assignment}
            addAssignment={this.props.addAssignment}
            deleteAssignment={this.props.deleteAssignment}
          />
          );
      });
      list = (
        <List
          elements={elements}
          keys={keys}
          sortable={true}
          table_key="category-articles"
          className="table--expandable table--hoverable"
          none_message={I18n.t('article_finder.no_article_found')}
          sortBy={this.props.sortArticleFinder}
        />
        );
    }

    let loader;
    if (this.state.isSubmitted && this.props.loading) {
      loader = <Loading />;
    }

    let fetchMoreButton;
    if (this.props.continue_results) {
      fetchMoreButton = (
        <button className="button dark text-center fetch-more" onClick={this.fetchMoreResults}>{I18n.t('article_finder.more_results')}</button>
      );
    }

    let searchStats;
    if (!this.props.loading && this.state.isSubmitted) {
      const fetchedCount = Object.keys(this.props.unfilteredArticles).length;
      const filteredCount = Object.keys(this.props.articles).length;
      searchStats = (
        <div>
          <div className="stat-display">
            <div className="stat-display__stat" id="articles-fetched">
              <div className="stat-display__value">{fetchedCount}</div>
              <small>{I18n.t('article_finder.fetched_articles')}</small>
            </div>
            <div className="stat-display__stat" id="articles-filtered">
              <div className="stat-display__value">{filteredCount}</div>
              <small>{I18n.t('article_finder.filtered_articles')}</small>
            </div>
          </div>
        </div>
        );
    }

    const loaderMessage = {
      ARTICLES_LOADING: I18n.t('article_finder.searching_articles'),
      TITLE_RECEIVED: I18n.t('article_finder.fetching_assessments'),
      PAGEASSESSMENT_RECEIVED: I18n.t('article_finder.fetching_revisions'),
      REVISION_RECEIVED: I18n.t('article_finder.fetching_scores'),
      REVISIONSCORE_RECEIVED: I18n.t('article_finder.fetching_pageviews'),
    };

    let fetchingLoader;
    if (this.props.fetchState !== "PAGEVIEWS_RECEIVED" && !this.props.loading) {
      fetchingLoader = (
        <div className="text-center">
          <div className="loading__spinner__small" />
          {loaderMessage[this.props.fetchState]}
        </div>
        );
    }

    let feedbackButton;
    if (this.state.isSubmitted && !this.props.loading) {
      feedbackButton = (
        <a className="button small pull-right" href={`/feedback?subject=Article Finder — ${this.props.search_term}`} target="_blank">How did the article finder work for you?</a>
      );
    }
    return (
      <div className="container">
        <header>
          <h1 className="title">{I18n.t('article_finder.article_finder')}</h1>
          <div>
            {I18n.t('article_finder.subheading_message')}
          </div>
        </header>
        <div className="article-finder-form">
          <div className="search-bar">
            <div>
              {searchTerm}
              {searchType}
            </div>
            <button className="button dark" onClick={this.searchArticles}>{I18n.t('article_finder.submit')}</button>
          </div>
        </div>
        {feedbackButton}
        {filterBlock}
        <div className="article-finder-stats horizontal-flex">
          {searchStats}
          <div>
            {fetchingLoader}
          </div>
          <div>
            {fetchMoreButton}
          </div>
        </div>
        {loader}
        {list}
        <div className="py2 text-center">
          {fetchMoreButton}
        </div>
      </div>
      );
  }
});

const mapStateToProps = state => ({
  articles: getFilteredArticleFinder(state),
  unfilteredArticles: state.articleFinder.articles,
  loading: state.articleFinder.loading,
  search_term: state.articleFinder.search_term,
  min_views: state.articleFinder.min_views,
  article_quality: state.articleFinder.article_quality,
  depth: state.articleFinder.depth,
  search_type: state.articleFinder.search_type,
  continue_results: state.articleFinder.continue_results,
  offset: state.articleFinder.offset,
  cmcontinue: state.articleFinder.cmcontinue,
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading,
  fetchState: state.articleFinder.fetchState,
  sort: state.articleFinder.sort,
});

const mapDispatchToProps = {
  fetchCategoryResults: fetchCategoryResults,
  updateFields: updateFields,
  addAssignment: addAssignment,
  fetchAssignments: fetchAssignments,
  sortArticleFinder: sortArticleFinder,
  fetchKeywordResults: fetchKeywordResults,
  deleteAssignment: deleteAssignment,
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticleFinder);
