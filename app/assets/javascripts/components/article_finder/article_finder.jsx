import React, { useState, useEffect, useRef } from 'react';
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

const ArticleFinder = (props) => {
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const searchboxRef = useRef(null);

  useEffect(() => {
    if (window.location.search.substring(1)) {
      getParamsURL();
    }
    if (props.course_id && props.loadingAssignments) {
      props.fetchAssignments(props.course_id);
    }
    if (props.router.location.project) {
      updateFieldsHandler('wiki', { language: props.router.location.language, project: props.router.location.project });
    } else {
      updateFieldsHandler('home_wiki', props.course.home_wiki);
    }
    return () => {
      props.resetArticleFinder();
    };
  }, []);
  const onKeyDown = (keyCode, ref) => {
    if (keyCode === 13) {
      ref.blur();
      searchArticles();
    }
  };

  const getParamsURL = () => {
    const query = qs.parse(window.location.search);
    const entries = Object.entries(query);
    entries.map(([key, val]) => {
      val = (key === 'article_quality') ? parseInt(val) : val;
      return updateFieldsHandler(key, val);
    });
  };

  const updateFieldsHandler = (key, value) => {
    const update_field = props.updateFields(key, value);
    Promise.resolve(update_field).then(() => {
      if (props.search_term.length !== 0 || key === 'search_term') {
        buildURL(key, value);
      }
    });
  };

  const toggleFilter = () => {
    setShowFilters(!showFilters);
  };

  const buildURL = (key, value) => {
    let queryStringUrl = window.location.href.split('?')[0];
    const params_array = ['search_type', 'article_quality', 'min_views'];
    const latestSearch = (key === 'search_term') ? value : props.search_term;
    queryStringUrl += `?search_term=${latestSearch}`;
    params_array.forEach((param) => {
      return queryStringUrl += (param === key) ? `&${param}=${value}` : `&${param}=${props[param]}`;
    });
    history.replaceState(window.location.href, 'query_string', queryStringUrl);
  };
  const searchArticles = async () => {
    setIsSubmitted(true);
    const searchTerm = window.location.href.match(/search_term=([^&]*)/)[1];
    if (searchTerm === '') {
      return setIsSubmitted(false);
    } else if (props.search_type === 'keyword') {
      return props.fetchKeywordResults(searchTerm, props.selectedWiki);
    }
    return props.fetchCategoryResults(searchTerm, props.selectedWiki);
  };
  const fetchMoreResults = () => {
    if (props.search_type === 'keyword') {
      return props.fetchKeywordResults(props.search_term, props.selectedWiki, props.offset, true);
    }
    return props.fetchCategoryResults(props.search_term, props.selectedWiki, props.cmcontinue, true);
  };
  // const handleChange = (e) => {
  //   const grade = e.target.value;
  //   return props.updateFields('grade', grade);
  // };
  const handleWikiChange = (wiki) => {
    wiki = wiki.value;
    setIsSubmitted(false);
    props.clearResults();
    return updateFieldsHandler('wiki', { language: wiki.language, project: wiki.project });
  };
  // const sortSelect = (e) => {
  //   props.sortArticleFinder(e.target.value);
  // };

    const searchType = (
      <div>
        <div className="search-type">
          <div>
            <label>
              <input type="radio" value="keyword" checked={props.search_type === 'keyword'} onChange={e => updateFieldsHandler('search_type', e.target.value)} />
              {I18n.t('article_finder.keyword_search')}
            </label>
          </div>
          <div>
            <label>
              <input type="radio" value="category" checked={props.search_type === 'category'} onChange={e => updateFieldsHandler('search_type', e.target.value)} />
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
          onChange={updateFieldsHandler}
          value={props.min_views}
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
          <label className="mb2">{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'article_quality')}`)}</label>
          <InputRange
            maxValue={100}
            minValue={0}
            value={props.article_quality}
            onChange={value => updateFieldsHandler('article_quality', value)}
            step={1}
          />
        </div>
      </div>
    );
    let filters;
    if (showFilters) {
      filters = (
        <div className="filters">
          {minimumViews}
          {articleQuality}
          {searchType}
        </div>
      );
    }

    let filterButton;
    if (!showFilters) {
      filterButton = (
        <button className="button dark" onClick={toggleFilter}>{I18n.t('article_finder.show_options')}</button>
      );
    } else {
      filterButton = (
        <button className="button" onClick={toggleFilter}>{I18n.t('article_finder.hide_options')}</button>
      );
    }

    let filterBlock;
    if (isSubmitted && !props.loading) {
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
    if (props.sort.key) {
      const order = (props.sort.sortKey) ? 'asc' : 'desc';
      keys[props.sort.key].order = order;
    }
  if (!includes(ORESSupportedWiki.languages, props.selectedWiki.language) || !includes(ORESSupportedWiki.projects, props.selectedWiki.project)) {
      delete keys.revScore;
    }

    if (!PageAssessmentSupportedWiki[props.selectedWiki.project] || !includes(PageAssessmentSupportedWiki[props.selectedWiki.project], props.selectedWiki.language)) {
      delete keys.grade;
    }

    if (!props.course_id || !props.current_user.id || props.current_user.notEnrolled) {
      delete keys.tools;
    }

    let list;
    if (isSubmitted && !props.loading) {
      const modifiedAssignmentsArray = map(props.assignments, (element) => {
          if (!element.language && !element.project) {
            return {
                ...element,
                language: props.selectedWiki.language,
                project: props.selectedWiki.project
              };
          }
          return element;
      });

      const elements = map(props.articles, (article, title) => {
        let assignment;
        if (props.course_id) {
          if (props.current_user.isAdvancedRole) {
            assignment = find(modifiedAssignmentsArray, { article_title: title, user_id: null, language: props.selectedWiki.language, project: props.selectedWiki.project });
          } else if (props.current_user.role === STUDENT_ROLE) {
            assignment = find(modifiedAssignmentsArray, { article_title: title, user_id: props.current_user.id, language: props.selectedWiki.language, project: props.selectedWiki.project });
          }
        }

        return (
          <ArticleFinderRow
            article={article}
            title={title}
            label={props.wikidataLabels[title]}
            key={article.pageid}
            courseSlug={props.course_id}
            course={props.course}
            selectedWiki={props.selectedWiki}
            assignment={assignment}
            addAssignment={props.addAssignment}
            deleteAssignment={props.deleteAssignment}
            current_user={props.current_user}
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
          none_message={I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'no_article_found')}`)}
          sortBy={props.sortArticleFinder}
        />
      );
    }

    let loader;
    if (isSubmitted && props.loading) {
      loader = <Loading />;
    }

    let fetchMoreButton;
    if (props.continue_results && isSubmitted) {
      fetchMoreButton = (
        <button className="button dark text-center fetch-more" onClick={fetchMoreResults}>{I18n.t('article_finder.more_results')}</button>
      );
    }

    let searchStats;
    if (!props.loading && isSubmitted) {
      const fetchedCount = Object.keys(props.unfilteredArticles).length;
      const filteredCount = Object.keys(props.articles).length;
      searchStats = (
        <div>
          <div className="stat-display">
            <div className="stat-display__stat" id="articles-fetched">
              <div className="stat-display__value">{fetchedCount}</div>
              <small>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'fetched_articles')}`)}</small>
            </div>
            <div className="stat-display__stat" id="articles-filtered">
              <div className="stat-display__value">{filteredCount}</div>
              <small>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'filtered_articles')}`)}</small>
            </div>
          </div>
        </div>
      );
    }

    const loaderMessage = {
      ARTICLES_LOADING: I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'searching_articles')}`),
      TITLE_RECEIVED: I18n.t('article_finder.fetching_assessments'),
      PAGEASSESSMENT_RECEIVED: I18n.t('article_finder.fetching_revisions'),
      REVISION_RECEIVED: I18n.t('article_finder.fetching_scores'),
      REVISIONSCORE_RECEIVED: I18n.t('article_finder.fetching_pageviews'),
    };

    let fetchingLoader;
    if (props.fetchState !== 'PAGEVIEWS_RECEIVED' && !props.loading) {
      fetchingLoader = (
        <div className="text-center">
          <div className="loading__spinner__small" />
          {loaderMessage[props.fetchState]}
        </div>
      );
    }

    const trackedWikis = trackedWikisMaker(props.course);

    const options = (
      <SelectedWikiOption
        language={props.selectedWiki.language || 'www'}
        project={props.selectedWiki.project}
        handleWikiChange={handleWikiChange}
        trackedWikis={trackedWikis}
      />
    );

    return (
      <div className="container">
        <header>
          <h1 className="title">{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'article_finder')}`)}</h1>
          <div>
            {I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'subheading_message')}`)}
          </div>
        </header>
        <div className="article-finder-form">
          <div className="search-bar" style={{ display: 'flex', flexDirection: 'row', alignItems: 'end' }}>
            <TextInput
              id="category"
              onChange={updateFieldsHandler}
              value={props.search_term}
              value_key="search_term"
              required
              editable
              label={I18n.t('article_finder.search')}
              placeholder={I18n.t('article_finder.search_placeholder')}
              onKeyDown={onKeyDown}
              ref={searchboxRef}
            />
            <button style={{ marginBottom: '8px' }} className={`button dark ${(props.fetchState !== 'PAGEVIEWS_RECEIVED' && !props.loading) ? 'disabled' : ''}`} onClick={searchArticles}>{I18n.t('article_finder.submit')}</button>
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
};

const mapStateToProps = state => ({
  articles: getFilteredArticleFinder(state),
  unfilteredArticles: state.articleFinder.articles,
  wikidataLabels: state.wikidataLabels.labels,
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
  selectedWiki: state.articleFinder.wiki || state.articleFinder.home_wiki
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

ArticleFinder.defaultProps = {
  course: {
    home_wiki: {
      language: 'en',
      project: 'wikipedia'
    }
  }
};
