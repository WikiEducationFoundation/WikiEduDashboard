import React, { useState, useEffect, useCallback, useMemo } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { useLocation, useNavigate } from 'react-router-dom';
import * as ArticleActions from '../../actions/article_actions';
import List from '../common/list.jsx';
import Article from './article.jsx';
import CourseOresPlot from './course_ores_plot.jsx';
import articleListKeys from './article_list_keys';
import ArticleUtils from '../../utils/article_utils.js';
import { parse, stringify } from 'query-string';
import { PaginatedArticleControls } from './PaginatedArticleControls';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select';

const defaults_params = { wiki: 'all', tracked: 'tracked', newness: 'both' };

const ArticleList = ({
  articles,
  course,
  current_user,
  actions,
  articleDetails,
  sortArticles,
  wikidataLabels,
  sort,
  wikiFilter,
  newnessFilter,
  trackedStatusFilter,
  wikis,
  newnessFilterEnabled,
  trackedStatusFilterEnabled,
  course_id,
  limit,
  limitReached,
  filterArticles,
  filterNewness,
  filterTrackedStatus,
  fetchArticles,
}) => {
  const location = useLocation();
  const navigate = useNavigate();
  const [selectedIndex, setSelectedIndex] = useState(-1);

  // Memoize complex computations
  const keys = useMemo(() => articleListKeys(course), [course]);
  const project = useMemo(() => course.home_wiki.project, [course]);

  const updateParams = useCallback((filter, value) => {
    const params = parse(location.search);
    if (defaults_params[filter] === value) {
      delete params[filter];
    } else {
      params[filter] = value;
    }
    navigate(`?${stringify(params)}`, { replace: true });
  }, [location.search, navigate]);

  const wikiObjectToString = useCallback((wikiFilterObj) => {
    return wikiFilterObj.language
      ? `${wikiFilterObj.language}.${wikiFilterObj.project}`
      : wikiFilterObj.project;
  }, []);

  // Effect for initialization
  useEffect(() => {
    const { wiki, newness, tracked } = parse(location.search);

    if (wiki !== undefined) {
      const value = wiki.split('.');
      filterArticles({
        language: value.length > 1 ? value[0] : null,
        project: value.length > 1 ? value[1] : value[0]
      });
    } else {
      updateParams('wiki', wikiObjectToString(wikiFilter));
    }

    if (newness !== undefined) {
      filterNewness(newness);
    } else {
      updateParams('newness', newnessFilter);
    }

    if (tracked !== undefined) {
      filterTrackedStatus(tracked);
    } else {
      updateParams('tracked', trackedStatusFilter);
    }

    // Set document title
    document.title = `${course.title} - ${ArticleUtils.I18n('edited', project)}`;
  }, []);

  // Effects for filter changes
  useEffect(() => {
    updateParams('wiki', wikiObjectToString(wikiFilter));
  }, [wikiFilter, updateParams, wikiObjectToString]);

  useEffect(() => {
    updateParams('newness', newnessFilter);
  }, [newnessFilter, updateParams]);

  useEffect(() => {
    updateParams('tracked', trackedStatusFilter);
  }, [trackedStatusFilter, updateParams]);

  // Event handlers
  const onChangeFilter = useCallback((e) => {
    const value = e.target.value.split('.');
    filterArticles({
      language: value.length > 1 ? value[0] : null,
      project: value.length > 1 ? value[1] : value[0]
    });
  }, [filterArticles]);

  const onNewnessChange = useCallback((e) => {
    filterNewness(e.target.value);
  }, [filterNewness]);

  const onTrackedFilterChange = useCallback((e) => {
    filterTrackedStatus(e.target.value);
  }, [filterTrackedStatus]);

  const showDiff = useCallback((index) => {
    setSelectedIndex(index);
  }, []);

  const showMore = useCallback(() => {
    fetchArticles(course_id, limit + 500);
  }, [fetchArticles, course_id, limit]);

  const sortSelect = useCallback((e) => {
    sortArticles(e.value);
  }, [sortArticles]);

  // Prepare UI elements
  const trackedEditable = current_user && current_user.isAdvancedRole;

  if (course.type !== 'ClassroomProgramCourse' && trackedEditable) {
    keys.tracked = {
      label: I18n.t('articles.tracked'),
      desktop_only: true,
      sortable: false,
      info_key: `${ArticleUtils.articlesOrItems(project)}.tracked_doc`
    };
  }

  if (sort.key) {
    const order = sort.sortKey ? 'asc' : 'desc';
    keys[sort.key].order = order;
  }

  const showArticleId = Number(location.search.split('showArticle=')[1]);
  const deletedMessage = I18n.t('articles.deleted_message');
  const pageLogsMessage = I18n.t('articles.page_logs');

  const articleElements = useMemo(() => articles.map((article, index) => (
    <Article
      article={article}
      index={index}
      showOnMount={showArticleId === article.id}
      course={course}
      key={article.id}
      wikidataLabel={wikidataLabels[article.title]}
      current_user={current_user}
      fetchArticleDetails={actions.fetchArticleDetails}
      updateArticleTrackedStatus={actions.updateArticleTrackedStatus}
      articleDetails={articleDetails[article.id] || null}
      setSelectedIndex={showDiff}
      lastIndex={articles.length}
      selectedIndex={selectedIndex}
      deletedMessage={deletedMessage}
      pageLogsMessage={pageLogsMessage}
    />
  )), [articles, showArticleId, course, wikidataLabels, current_user, actions, articleDetails, showDiff, selectedIndex, deletedMessage, pageLogsMessage]);

  const header = Features.wikiEd
    ? <h3 className="article tooltip-trigger">{ArticleUtils.I18n('edited', project)}</h3>
    : (
      <h3 className="article tooltip-trigger">
        {ArticleUtils.I18n('edited', project)}
        <span className="tooltip-indicator-heading" />
        <div className="tooltip dark">
          <p>{ArticleUtils.I18n('cross_wiki_tracking', project)}</p>
        </div>
      </h3>
    );

  const wikiFilterValue = wikiObjectToString(wikiFilter);

  const filterWikis = wikis.length > 1 && (
    <select onChange={onChangeFilter} value={wikiFilterValue}>
      <option value="all">{I18n.t('articles.filter.wiki_all')}</option>
      {wikis.map((wiki) => {
        const wikiString = `${wiki.language ? `${wiki.language}.` : ''}${wiki.project}`;
        return <option value={wikiString} key={wikiString}>{wikiString}</option>;
      })}
    </select>
  );

  const filterArticlesSelect = newnessFilterEnabled && (
    <select
      className="filter-articles"
      value={newnessFilter}
      onChange={onNewnessChange}
    >
      <option value="new">{I18n.t('articles.filter.new')}</option>
      <option value="existing">{I18n.t('articles.filter.existing')}</option>
      <option value="both">{I18n.t('articles.filter.new_and_existing')}</option>
    </select>
  );

  const filterTracked = trackedStatusFilterEnabled && (
    <select
      className="filter-articles"
      value={trackedStatusFilter}
      onChange={onTrackedFilterChange}
    >
      <option value="tracked">{I18n.t('articles.filter.tracked')}</option>
      <option value="untracked">{I18n.t('articles.filter.untracked')}</option>
      <option value="both">{I18n.t('articles.filter.tracked_and_untracked')}</option>
    </select>
  );

  const filterLabel = (filterWikis || filterArticlesSelect || filterTracked) && (
    <b>{I18n.t('articles.filter_text')}</b>
  );

  const options = [
    { value: 'rating_num', label: I18n.t('articles.rating') },
    { value: 'title', label: I18n.t('articles.title') },
    { value: 'character_sum', label: I18n.t('metrics.char_added') },
    { value: 'references_count', label: I18n.t('metrics.references_count') },
    { value: 'view_count', label: I18n.t('metrics.view') },
  ];

  const articleSort = (
    <div className="sort-container">
      <Select
        onChange={sortSelect}
        name="sorts"
        options={options}
        styles={sortSelectStyles}
      />
    </div>
  );

  const sectionHeader = (
    <div className="section-header">
      {header}
      <CourseOresPlot course={course} />
      <div className="wrap-filters">
        {filterLabel}
        {filterTracked}
        {filterArticlesSelect}
        {filterWikis}
        {articleSort}
      </div>
    </div>
  );

  const showMoreSection = (
    <div className="see-more">
      <PaginatedArticleControls showMore={showMore} limitReached={limitReached} />
    </div>
  );

  return (
    <div id="articles" className="mt4">
      {sectionHeader}
      {showMoreSection}
      <List
        elements={articleElements}
        keys={keys}
        sortable={true}
        table_key="articles"
        className="table--expandable table--hoverable"
        none_message={ArticleUtils.I18n('edited_none', project)}
        sortBy={sortArticles}
      />
    </div>
  );
};

ArticleList.propTypes = {
  articles: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  actions: PropTypes.object.isRequired,
  articleDetails: PropTypes.object.isRequired,
  sortArticles: PropTypes.func.isRequired,
  wikidataLabels: PropTypes.object.isRequired,
  sort: PropTypes.object.isRequired,
  wikiFilter: PropTypes.object.isRequired,
  newnessFilter: PropTypes.string.isRequired,
  trackedStatusFilter: PropTypes.string.isRequired,
  wikis: PropTypes.array.isRequired,
  newnessFilterEnabled: PropTypes.bool.isRequired,
  trackedStatusFilterEnabled: PropTypes.bool.isRequired,
  course_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  limit: PropTypes.number.isRequired,
  limitReached: PropTypes.bool.isRequired,
  filterArticles: PropTypes.func.isRequired,
  filterNewness: PropTypes.func.isRequired,
  filterTrackedStatus: PropTypes.func.isRequired,
  fetchArticles: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  articleDetails: state.articleDetails,
  sort: state.articles.sort,
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(ArticleList);
