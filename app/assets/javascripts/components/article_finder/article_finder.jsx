import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import InputRange from 'react-input-range';
import { includes, map, find } from 'lodash-es';
import qs from 'query-string';
import SelectedWikiOption from '../common/selected_wiki_option';
import { compose } from 'redux';
import withRouter from '../util/withRouter';

import TextInput from '../common/text_input.jsx';
import ArticleFinderRow from './article_finder_row.jsx';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

import { STUDENT_ROLE } from '../../constants';
import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../../utils/article_finder_language_mappings.js';
import { fetchCategoryResults, fetchKeywordResults, updateFields, sortArticleFinder, resetArticleFinder, clearResults } from '../../actions/article_finder_action.js';
import { fetchAssignments, addAssignment, deleteAssignment } from '../../actions/assignment_actions.js';
import { getFilteredArticleFinder } from '../../selectors';

import { trackedWikisMaker } from '../../utils/wiki_utils';
import ArticleUtils from '../../utils/article_utils';

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

  componentDidMount() {
    if (window.location.search.substring(1)) {
      this.getParamsURL();
    }
    if (this.props.course_id && this.props.loadingAssignments) {
      this.props.fetchAssignments(this.props.course_id);
    }
    if (this.props.router.location.project) {
      return this.updateFields('home_wiki', { language: this.props.router.location.language, project: this.props.router.location.project });
    }
    return this.updateFields('home_wiki', this.props.course.home_wiki);
  },

  componentWillUnmount() {
    return this.props.resetArticleFinder();
  },

  onKeyDown(keyCode, ref) {
    if (keyCode === 13) {
      ref.blur();
      this.searchArticles();
    }
  },

  getParamsURL() {
    const query = qs.parse(window.location.search);
    const entries = Object.entries(query);
    entries.map(([key, val]) => {
      val = (key === 'article_quality') ? parseInt(val) : val;
      return this.updateFields(key, val);
    });
  },

  updateFields(key, value) {
    const update_field = this.props.updateFields(key, value);
    Promise.resolve(update_field).then(() => {
      if (this.props.search_term.length !== 0) {
        this.buildURL();
      }
    });
  },

  toggleFilter() {
    return this.setState({
      showFilters: !this.state.showFilters
    });
  },
  buildURL() {
    let queryStringUrl = window.location.href.split('?')[0];
    const params_array = ['search_type', 'article_quality', 'min_views'];
    queryStringUrl += `?search_term=${this.props.search_term}`;
    params_array.forEach((param) => {
      return queryStringUrl += `&${param}=${this.props[param]}`;
    });
    history.replaceState(window.location.href, 'query_string', queryStringUrl);
  },
  searchArticles() {
    this.setState({
      isSubmitted: true,
    });
    if (this.props.search_term === '') {
      return this.setState({
        isSubmitted: false,
      });
    } else if (this.props.search_type === 'keyword') {
      this.buildURL();
      return this.props.fetchKeywordResults(this.props.search_term, this.props.home_wiki);
    }
    return this.props.fetchCategoryResults(this.props.search_term, this.props.home_wiki);
  },

  fetchMoreResults() {
    if (this.props.search_type === 'keyword') {
      return this.props.fetchKeywordResults(this.props.search_term, this.props.home_wiki, this.props.offset, true);
    }
    return this.props.fetchCategoryResults(this.props.search_term, this.props.home_wiki, this.props.cmcontinue, true);
  },

  handleChange(e) {
    const grade = e.target.value;
    return this.props.updateFields('grade', grade);
  },

  handleWikiChange(wiki) {
    wiki = wiki.value;
    this.setState({ isSubmitted: false });
    this.props.clearResults();
    return this.updateFields('home_wiki', { language: wiki.language, project: wiki.project });
  },

  sortSelect(e) {
    this.props.sortArticleFinder(e.target.value);
  },

  render() {
    const searchButton = <button className="button dark" onClick={this.searchArticles}>{I18n.t('article_finder.submit')}</button>;
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
      >{searchButton}
      </TextInput>);

    const searchType = (
      <div>
        <div className="search-type">
          <div>
            <label>
              <input type="radio" value="keyword" checked={this.props.search_type === 'keyword'} onChange={e => this.updateFields('search_type', e.target.value)} />
              {I18n.t('article_finder.keyword_search')}
            </label>
          </div>
          <div>
            <label>
              <input type="radio" value="category" checked={this.props.search_type === 'category'} onChange={e => this.updateFields('search_type', e.target.value)} />
              {I18n.t('article_finder.category_search')}
            </label>
          </div>
        </div>
      </div>
    );

    const minimumViews = (
      <div>
        <TextInput
          id="min_views"
          onChange={this.updateFields}
          value={this.props.min_views}
          value_key="min_views"
          required
          editable
          label={I18n.t('article_finder.minimum_views_label')}
          placeholder={I18n.t('article_finder.minimum_views_label')}
        />
      </div>
    );

    const articleQuality = (
      <div>
        <div className="form-group range-container">
          <label className="mb2">{I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'article_quality')}`)}</label>
          <InputRange
            maxValue={100}
            minValue={0}
            value={this.props.article_quality}
            onChange={value => this.updateFields('article_quality', value)}
            step={1}
          />
        </div>
      </div>
    );
    let filters;
    if (this.state.showFilters) {
      filters = (
        <div className="filters">
          {minimumViews}
          {articleQuality}
          {searchType}
        </div>
      );
    }

    let filterButton;
    if (!this.state.showFilters) {
      filterButton = (
        <button className="button dark" onClick={this.toggleFilter}>{I18n.t('article_finder.show_options')}</button>
      );
    } else {
      filterButton = (
        <button className="button" onClick={this.toggleFilter}>{I18n.t('article_finder.hide_options')}</button>
      );
    }

    let filterBlock;
    if (this.state.isSubmitted && !this.props.loading) {
      filterBlock = (
        <div className="filter-block">
          <div className="filter-button-block">
            {filterButton}
          </div>
          <div className="filter-items">
            {filters}
          </div>
        </div>
      );
    }

    const keys = {
      relevanceIndex: {
        label: I18n.t('article_finder.relevanceIndex'),
        desktop_only: false
      },
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
    if (!includes(ORESSupportedWiki.languages, this.props.home_wiki.language) || !includes(ORESSupportedWiki.projects, this.props.home_wiki.project)) {
      delete keys.revScore;
    }

    if (!PageAssessmentSupportedWiki[this.props.home_wiki.project] || !includes(PageAssessmentSupportedWiki[this.props.home_wiki.project], this.props.home_wiki.language)) {
      delete keys.grade;
    }

    if (!this.props.course_id || !this.props.current_user.id || this.props.current_user.notEnrolled) {
      delete keys.tools;
    }

    let list;
    if (this.state.isSubmitted && !this.props.loading) {
      const modifiedAssignmentsArray = map(this.props.assignments, (element) => {
          if (!element.language && !element.project) {
            return {
                ...element,
                language: this.props.home_wiki.language,
                project: this.props.home_wiki.project
              };
          }
          return element;
      });

      const elements = map(this.props.articles, (article, title) => {
        let assignment;
        if (this.props.course_id) {
          if (this.props.current_user.isAdvancedRole) {
            assignment = find(modifiedAssignmentsArray, { article_title: title, user_id: null, language: this.props.home_wiki.language, project: this.props.home_wiki.project });
          } else if (this.props.current_user.role === STUDENT_ROLE) {
            assignment = find(modifiedAssignmentsArray, { article_title: title, user_id: this.props.current_user.id, language: this.props.home_wiki.language, project: this.props.home_wiki.project });
          }
        }

        return (
          <ArticleFinderRow
            article={article}
            title={title}
            key={article.pageid}
            courseSlug={this.props.course_id}
            course={this.props.course}
            home_wiki={this.props.home_wiki}
            assignment={assignment}
            addAssignment={this.props.addAssignment}
            deleteAssignment={this.props.deleteAssignment}
            current_user={this.props.current_user}
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
          none_message={I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'no_article_found')}`)}
          sortBy={this.props.sortArticleFinder}
        />
      );
    }

    let loader;
    if (this.state.isSubmitted && this.props.loading) {
      loader = <Loading />;
    }

    let fetchMoreButton;
    if (this.props.continue_results && this.state.isSubmitted) {
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
              <small>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'fetched_articles')}`)}</small>
            </div>
            <div className="stat-display__stat" id="articles-filtered">
              <div className="stat-display__value">{filteredCount}</div>
              <small>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'filtered_articles')}`)}</small>
            </div>
          </div>
        </div>
      );
    }

    const loaderMessage = {
      ARTICLES_LOADING: I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'searching_articles')}`),
      TITLE_RECEIVED: I18n.t('article_finder.fetching_assessments'),
      PAGEASSESSMENT_RECEIVED: I18n.t('article_finder.fetching_revisions'),
      REVISION_RECEIVED: I18n.t('article_finder.fetching_scores'),
      REVISIONSCORE_RECEIVED: I18n.t('article_finder.fetching_pageviews'),
    };

    let fetchingLoader;
    if (this.props.fetchState !== 'PAGEVIEWS_RECEIVED' && !this.props.loading) {
      fetchingLoader = (
        <div className="text-center">
          <div className="loading__spinner__small" />
          {loaderMessage[this.props.fetchState]}
        </div>
      );
    }

    const trackedWikis = trackedWikisMaker(this.props.course);

    const options = (
      <SelectedWikiOption
        language={this.props.home_wiki.language || 'www'}
        project={this.props.home_wiki.project}
        handleWikiChange={this.handleWikiChange}
        trackedWikis={trackedWikis}
      />
    );

    return (
      <div className="container">
        <header>
          <h1 className="title">{I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'article_finder')}`)}</h1>
          <div>
            {I18n.t(`article_finder.${ArticleUtils.projectSuffix(this.props.home_wiki.project, 'subheading_message')}`)}
          </div>
        </header>
        <div className="article-finder-form">
          <div className="search-bar">
            {searchTerm}
          </div>
        </div>
        {options}
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
  labels: state.wikidataLabels.labels,
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
  home_wiki: state.articleFinder.home_wiki,
});

const mapDispatchToProps = {
  fetchCategoryResults: fetchCategoryResults,
  updateFields: updateFields,
  addAssignment: addAssignment,
  fetchAssignments: fetchAssignments,
  sortArticleFinder: sortArticleFinder,
  fetchKeywordResults: fetchKeywordResults,
  deleteAssignment: deleteAssignment,
  resetArticleFinder: resetArticleFinder,
  clearResults: clearResults,
};

export default compose(
  withRouter,
  connect(mapStateToProps, mapDispatchToProps)
)(ArticleFinder);
