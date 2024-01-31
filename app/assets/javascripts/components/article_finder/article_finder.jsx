import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useDispatch } from 'react-redux';
import InputRange from 'react-input-range';
import { includes, map, find } from 'lodash-es';
import qs from 'query-string';
import SelectedWikiOption from '../common/selected_wiki_option';
import TextInput from '../common/text_input.jsx';
import ArticleFinderRow from './article_finder_row.jsx';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';
import { STUDENT_ROLE } from '../../constants';
import {
  ORESSupportedWiki,
  PageAssessmentSupportedWiki,
} from '../../utils/article_finder_language_mappings.js';
import {
  fetchCategoryResults,
  fetchKeywordResults,
  updateFields,
  sortArticleFinder,
  resetArticleFinder,
  clearResults,
} from '../../actions/article_finder_action.js';
import {
  fetchAssignments,
  addAssignment,
  deleteAssignment,
} from '../../actions/assignment_actions.js';
import { trackedWikisMaker } from '../../utils/wiki_utils';
import ArticleUtils from '../../utils/article_utils';
import { useLocation } from 'react-router-dom';
import { table_keys } from './constants';
import useInitialiseArticleFinder from './hooks/useInitialiseArticleFinder';

const ArticleFinder = (props) => {
  const dispatch = useDispatch();
  const location = useLocation();

  const {
    course_id,
    current_user,
    course = {
      home_wiki: {
        language: 'en',
        project: 'wikipedia',
      },
    },
  } = props;

  const {
    articles,
    unfilteredArticles,
    wikidataLabels,
    loading,
    search_term,
    min_views,
    article_quality,
    search_type,
    continue_results,
    offset,
    cmcontinue,
    assignments,
    loadingAssignments,
    fetchState,
    sort,
    home_wiki,
    selectedWiki,
    buildURL,
  } = useInitialiseArticleFinder();

  const [isSubmitted, setIsSubmitted] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [_table_keys, setTableKeys] = useState(table_keys);
  const searchBoxRef = useRef('');

  useEffect(() => {
    const loadOnMount = () => {
      if (window.location.search.substring(1)) {
        getParamsURL();
      }
      if (course_id && loadingAssignments) {
        dispatch(fetchAssignments(course_id));
      }
      if (location.project) {
        return _updateFields('wiki', {
          language: location.language,
          project: location.project,
        });
      }
      return _updateFields('home_wiki', home_wiki);
    };
    loadOnMount();

    return () => {
      dispatch(clearResults());
      dispatch(resetArticleFinder());
    };
  }, []);

  useEffect(() => {
    const handleSortKey = () => {
      const newTableKeys = { ..._table_keys };
      if (sort.key) {
        const order = sort.sortKey ? 'asc' : 'desc';
        Object.entries(newTableKeys).forEach((item) => {
          const [key, value] = item;
          if (key === sort.key) {
            value.order = order;
          } else {
            delete value.order;
          }
        });
        console.log('newTableKeys', newTableKeys);
        setTableKeys(newTableKeys);
      }
      if (
        !includes(ORESSupportedWiki.languages, selectedWiki.language)
        || !includes(ORESSupportedWiki.projects, selectedWiki.project)
      ) {
        delete newTableKeys.revScore;
        setTableKeys(newTableKeys);
      }

      if (
        !PageAssessmentSupportedWiki[selectedWiki.project]
        || !includes(
          PageAssessmentSupportedWiki[selectedWiki.project],
          selectedWiki.language
        )
      ) {
        delete newTableKeys.grade;
        setTableKeys(newTableKeys);
      }

      if (!course_id || !current_user.id || current_user.notEnrolled) {
        delete newTableKeys.tools;
        setTableKeys(newTableKeys);
      }
    };

    handleSortKey();
  }, [
    sort.key,
    sort.sortKey,
    course_id,
    current_user.id,
    current_user.notEnrolled,
    PageAssessmentSupportedWiki[selectedWiki.project],
    ORESSupportedWiki,
  ]);

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
      val = key === 'article_quality' ? parseInt(val) : val;
      return _updateFields(key, val);
    });
  };

  const _updateFields = (key, value) => {
    dispatch(updateFields(key, value));
  };

  const toggleFilter = () => {
    setShowFilters(isShown => !isShown);
  };

  const searchArticles = () => {
    setIsSubmitted(true);
    if (search_term === '') {
      setIsSubmitted(false);
    } else if (search_type === 'keyword') {
      buildURL();
      return dispatch(fetchKeywordResults(search_term, selectedWiki));
    }
    return dispatch(fetchCategoryResults(search_term, selectedWiki));
  };

  const fetchMoreResults = () => {
    if (search_type === 'keyword') {
      return dispatch(
        fetchKeywordResults(search_term, selectedWiki, offset, true)
      );
    }
    return dispatch(
      fetchCategoryResults(search_term, selectedWiki, cmcontinue, true)
    );
  };

  const handleWikiChange = (wiki) => {
    wiki = wiki.value;
    setIsSubmitted(false);
    dispatch(clearResults());
    return _updateFields('wiki', {
      language: wiki.language,
      project: wiki.project,
    });
  };

  const searchTerm = (
    <TextInput
      id="category"
      onChange={_updateFields}
      value={search_term}
      value_key="search_term"
      required
      editable
      label={I18n.t('article_finder.search')}
      placeholder={I18n.t('article_finder.search_placeholder')}
      onKeyDown={onKeyDown}
      ref={searchBoxRef}
    >
      <button className="button dark" onClick={searchArticles}>
        {I18n.t('article_finder.submit')}
      </button>
    </TextInput>
  );

  const searchType = () => (
    <div>
      <div className="search-type">
        <div>
          <label>
            <input
              type="radio"
              value="keyword"
              checked={search_type === 'keyword'}
              onChange={e => _updateFields('search_type', e.target.value)}
            />
            {I18n.t('article_finder.keyword_search')}
          </label>
        </div>
        <div>
          <label>
            <input
              type="radio"
              value="category"
              checked={search_type === 'category'}
              onChange={e => _updateFields('search_type', e.target.value)}
            />
            {I18n.t('article_finder.category_search')}
          </label>
        </div>
      </div>
    </div>
  );

  const minimumViews = () => (
    <div>
      <TextInput
        id="min_views"
        onChange={_updateFields}
        value={min_views}
        value_key="min_views"
        required
        editable
        label={I18n.t('article_finder.minimum_views_label')}
        placeholder={I18n.t('article_finder.minimum_views_label')}
      />
    </div>
  );

  const articleQuality = () => (
    <div>
      <div className="form-group range-container">
        <label className="mb2">
          {I18n.t(
            `article_finder.${ArticleUtils.projectSuffix(
              selectedWiki.project,
              'article_quality'
            )}`
          )}
        </label>
        <InputRange
          maxValue={100}
          minValue={0}
          value={article_quality}
          onChange={value => _updateFields('article_quality', value)}
          step={1}
        />
      </div>
    </div>
  );

  const filterBtnClassAndText = useMemo(() => {
    if (!showFilters) {
      return {
        className: 'button dark',
        text: I18n.t('article_finder.show_options'),
      };
    }
    return {
      className: 'button',
      text: I18n.t('article_finder.hide_options'),
    };
  }, [showFilters]);

  const filterBlock = useMemo(() => {
    if (isSubmitted && !loading) {
      return (
        <div className="filter-block">
          <div className="filter-button-block">
            <button
              className={filterBtnClassAndText.className}
              onClick={toggleFilter}
            >
              {filterBtnClassAndText.text}
            </button>
          </div>
          {showFilters ? (
            <div className="filter-items">
              <div className="filters">
                {minimumViews()}
                {articleQuality()}
                {searchType()}
              </div>
            </div>
          ) : null}
        </div>
      );
    }
  }, [
    isSubmitted,
    loading,
    showFilters,
    minimumViews,
    articleQuality,
    searchType,
  ]);

  const _sortArticleFinder = (key) => {
    dispatch(sortArticleFinder(key));
  };

  const renderList = () => {
    const modifiedAssignmentsArray = map(assignments, (element) => {
      if (!element.language && !element.project) {
        return {
          ...element,
          language: selectedWiki.language,
          project: selectedWiki.project,
        };
      }
      return element;
    });

    const elements = map(articles, (article, title) => {
      let assignment;
      if (course_id) {
        if (current_user.isAdvancedRole) {
          assignment = find(modifiedAssignmentsArray, {
            article_title: title,
            user_id: null,
            language: selectedWiki.language,
            project: selectedWiki.project,
          });
        } else if (current_user.role === STUDENT_ROLE) {
          assignment = find(modifiedAssignmentsArray, {
            article_title: title,
            user_id: current_user.id,
            language: selectedWiki.language,
            project: selectedWiki.project,
          });
        }
      }

      return (
        <ArticleFinderRow
          article={article}
          title={title}
          label={wikidataLabels[title]}
          key={article.pageid}
          courseSlug={course_id}
          course={course}
          selectedWiki={selectedWiki}
          assignment={assignment}
          addAssignment={() => dispatch(addAssignment)}
          deleteAssignment={() => dispatch(deleteAssignment)}
          current_user={current_user}
        />
      );
    });

    return (
      <List
        elements={elements}
        keys={_table_keys}
        sortable={true}
        table_key="category-articles"
        className="table--expandable table--hoverable"
        none_message={I18n.t(
          `article_finder.${ArticleUtils.projectSuffix(
            selectedWiki.project,
            'no_article_found'
          )}`
        )}
        sortBy={_sortArticleFinder}
      />
    );
  };

  const fetchMoreButton = () => {
    return (
      <button
        className="button dark text-center fetch-more"
        onClick={fetchMoreResults}
      >
        {I18n.t('article_finder.more_results')}
      </button>
    );
  };

  const getSearchStats = () => {
    const fetchedCount = Object.keys(unfilteredArticles).length;
    const filteredCount = Object.keys(articles).length;
    return (
      <div>
        <div className="stat-display">
          <div className="stat-display__stat" id="articles-fetched">
            <div className="stat-display__value">{fetchedCount}</div>
            <small>
              {I18n.t(
                `article_finder.${ArticleUtils.projectSuffix(
                  selectedWiki.project,
                  'fetched_articles'
                )}`
              )}
            </small>
          </div>
          <div className="stat-display__stat" id="articles-filtered">
            <div className="stat-display__value">{filteredCount}</div>
            <small>
              {I18n.t(
                `article_finder.${ArticleUtils.projectSuffix(
                  selectedWiki.project,
                  'filtered_articles'
                )}`
              )}
            </small>
          </div>
        </div>
      </div>
    );
  };

  const loaderMessage = {
    ARTICLES_LOADING: I18n.t(
      `article_finder.${ArticleUtils.projectSuffix(
        selectedWiki.project,
        'searching_articles'
      )}`
    ),
    TITLE_RECEIVED: I18n.t('article_finder.fetching_assessments'),
    PAGEASSESSMENT_RECEIVED: I18n.t('article_finder.fetching_revisions'),
    REVISION_RECEIVED: I18n.t('article_finder.fetching_scores'),
    REVISIONSCORE_RECEIVED: I18n.t('article_finder.fetching_pageviews'),
  };

  const displayLoaderMessage = () => {
    return (
      <div className="text-center">
        <div className="loading__spinner__small" />
        {loaderMessage[fetchState]}
      </div>
    );
  };

  const options = (
    <SelectedWikiOption
      language={selectedWiki.language || 'www'}
      project={selectedWiki.project}
      handleWikiChange={handleWikiChange}
      trackedWikis={trackedWikis}
    />
  );

  const listStatus = isSubmitted && !loading;
  const isLoadingStatus = isSubmitted && loading;
  const isSubmittedButNotLoadingStatus = !loading && isSubmitted;
  const pageViewsRecievedStatus = fetchState !== 'PAGEVIEWS_RECEIVED' && !loading;
  const fetchMoreResultsStatus = continue_results && isSubmitted;

  const trackedWikis = trackedWikisMaker(course);

  return (
    <div className="container">
      <header>
        <h1 className="title">
          {I18n.t(
            `article_finder.${ArticleUtils.projectSuffix(
              selectedWiki.project,
              'article_finder'
            )}`
          )}
        </h1>
        <div>
          {I18n.t(
            `article_finder.${ArticleUtils.projectSuffix(
              selectedWiki.project,
              'subheading_message'
            )}`
          )}
        </div>
      </header>
      <div className="article-finder-form">
        <div className="search-bar">{searchTerm}</div>
      </div>
      {options}
      {filterBlock}
      <div className="article-finder-stats horizontal-flex">
        {isSubmittedButNotLoadingStatus ? getSearchStats() : null}
        <div>{pageViewsRecievedStatus ? displayLoaderMessage() : null}</div>
        <div>{fetchMoreResultsStatus ? fetchMoreButton() : null}</div>
      </div>
      {isLoadingStatus ? <Loading /> : null}
      {listStatus ? renderList() : null}
      <div className="py2 text-center">
        {fetchMoreResultsStatus ? fetchMoreButton() : null}
      </div>
    </div>
  );
};

export default ArticleFinder;
