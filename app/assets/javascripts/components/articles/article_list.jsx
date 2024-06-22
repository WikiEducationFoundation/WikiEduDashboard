import React, { useState, useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { useLocation } from 'react-router-dom';
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
  // Props are now destructured parameters instead of accessed via this.props
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
   // Now using useLocation hook instead of withRouter HOC for easier access to location
  const location = useLocation();
  const initializedRef = useRef(false);
  // Using useState hook to manage selectedIndex instead of this.state
  const [selectedIndex, setSelectedIndex] = useState(-1);

  useEffect(() => {
    if (!initializedRef.current) {
      initializedRef.current = true;
      const { wiki, newness, tracked } = parse(location.search);

      if (wiki !== undefined) {
        const value = wiki.split('.');
        filterArticles({
          language: value.length > 1 ? value[0] : null,
          project: value.length > 1 ? value[1] : value[0]
        });
      }

      if (newness !== undefined) {
        filterNewness(newness);
      }

      if (tracked !== undefined) {
        filterTrackedStatus(tracked);
      }
    }
  }, [location.search, filterArticles, filterNewness, filterTrackedStatus]);

  useEffect(() => {
    const wikiFilterValue = wikiObjectToString(wikiFilter);
    updateParams('wiki', wikiFilterValue);
  }, [wikiFilter]);

  useEffect(() => {
    updateParams('newness', newnessFilter);
  }, [newnessFilter]);

  useEffect(() => {
    updateParams('tracked', trackedStatusFilter);
  }, [trackedStatusFilter]);
   // Effect runs when these values change, similar to old componentDidUpdate lifecycle method

  useEffect(() => {
    // sets the title for this tab
    const project = course.home_wiki.project;
    document.title = `${course.title} - ${ArticleUtils.I18n('edited', project)}`;
  }, [course]);

  const onChangeFilter = (e) => {
    updateParams('wiki', e.target.value);
    const value = e.target.value.split('.');
    if (value.length > 1) {
      filterArticles({ language: value[0], project: value[1] });
    } else {
      filterArticles({ language: null, project: value[0] });
    }
  };
  const onNewnessChange = (e) => {
    updateParams('newness', e.target.value);
    filterNewness(e.target.value);
  };

  const onTrackedFilterChange = (e) => {
    updateParams('tracked', e.target.value);
    filterTrackedStatus(e.target.value);
  };

  const updateParams = (filter, value) => {
    // instead of using React Router's location, we must use window.location
    // this is because v6 of React Router doesn't have a mutable history object
    const search = window.location.search;
    const params = parse(search);

    // don't add the search param if the value is equal to the default value
    if (defaults_params[filter] === value) {
      // delete the existing key
      delete params[filter];
    } else {
      params[filter] = value;
    }
    window.history.replaceState(null, null, `?${stringify(params)}`);
  };

  const showDiff = (index) => {
    setSelectedIndex(index);
  };

  const showMore = () => {
    fetchArticles(Number(course_id), limit + 500);
  };

  const sortSelect = (e) => {
    sortArticles(e.value);
  };

  const wikiObjectToString = (wikiFilterObj) => {
    let wikiFilterValue;

    if (wikiFilterObj.language) {
      wikiFilterValue = `${wikiFilterObj.language}.${wikiFilterObj.project}`;
    } else {
      wikiFilterValue = `${wikiFilterObj.project}`;
    }
    return wikiFilterValue;
  };

    const keys = articleListKeys(course);
    const project = course.home_wiki.project;
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
      const order = (sort.sortKey) ? 'asc' : 'desc';
      keys[sort.key].order = order;
    }

    // If a parameter like ?showArticle=123 is present,
    // the ArticleViewer should go into show mode immediately.
    // this allows for links to directly view a specific article.
    const showArticleId = Number(location.search.split('showArticle=')[1]);
    const deletedMessage = I18n.t('articles.deleted_message');
    const pageLogsMessage = I18n.t('articles.page_logs');
    const articleElements = articles.map((article, index) => (
      <Article
        article={article}
        index={index}
        showOnMount={showArticleId === article.id}
        course={course}
        key={article.id}
        wikidataLabel={wikidataLabels[article.title]}
        // eslint-disable-next-line
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
    ));

    let header;
    if (Features.wikiEd) {
      header = <h3 className="article tooltip-trigger">{ArticleUtils.I18n('edited', project)}</h3>;
    } else {
      header = (
        <h3 className="article tooltip-trigger">{ArticleUtils.I18n('edited', project)}
          <span className="tooltip-indicator-heading" />
          <div className="tooltip dark">
            <p>{ArticleUtils.I18n('cross_wiki_tracking', project)}</p>
          </div>
        </h3>
      );
    }

    let filterWikis;
    const wikiFilterValue = wikiObjectToString(wikiFilter);

    if (wikis.length > 1) {
      const wikiOptions = wikis.map((wiki) => {
        const wikiString = `${wiki.language ? `${wiki.language}.` : ''}${wiki.project}`;
        return (<option value={wikiString} key={wikiString}>{wikiString}</option>);
      });

      filterWikis = (
        <select
          onChange={onChangeFilter}
          value={wikiFilterValue}
        >
          <option value="all">{I18n.t('articles.filter.wiki_all')}</option>
          {wikiOptions}
        </select>
      );
    }

    let filterArticlesSelect;
    if (newnessFilterEnabled) {
      filterArticlesSelect = (
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
    }

    let filterTracked;
    if (trackedStatusFilterEnabled) {
      filterTracked = (
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
    }

    let filterLabel;
    if (!!filterWikis || !!filterArticlesSelect || !!filterTracked) {
      filterLabel = <b>{I18n.t('articles.filter_text')}</b>;
    }

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
  articles: PropTypes.array,
  course: PropTypes.object,
  current_user: PropTypes.object,
  actions: PropTypes.object,
  articleDetails: PropTypes.object,
  sortArticles: PropTypes.func,
  wikidataLabels: PropTypes.object,
  sort: PropTypes.object,
  wikiFilter: PropTypes.object,
  newnessFilter: PropTypes.string,
  trackedStatusFilter: PropTypes.string,
  wikis: PropTypes.array,
  newnessFilterEnabled: PropTypes.bool,
  trackedStatusFilterEnabled: PropTypes.bool,
  course_id: PropTypes.number,
  limit: PropTypes.number,
  limitReached: PropTypes.bool,
  filterArticles: PropTypes.func,
  filterNewness: PropTypes.func,
  filterTrackedStatus: PropTypes.func,
  fetchArticles: PropTypes.func,
};

const mapStateToProps = (state) => {
  return ({
    articleDetails: state.articleDetails,
    sort: state.articles.sort,
  });
};

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(ArticleList);
