import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import withRouter from '../util/withRouter';
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

const ArticleList = createReactClass({
  displayName: 'ArticleList',

  propTypes: {
    articles: PropTypes.array,
    course: PropTypes.object,
    current_user: PropTypes.object,
    actions: PropTypes.object,
    articleDetails: PropTypes.object,
    sortArticles: PropTypes.func,
    wikidataLabels: PropTypes.object,
    sort: PropTypes.object
  },

  getInitialState() {
    // getting filters from the URL
    const { wiki, newness, tracked } = parse(this.props.router.location.search);

    // filter by "wiki"
    if (wiki !== undefined) {
      // wiki is passed as a search param
      const value = wiki.split('.');
      if (value.length > 1) {
        this.props.filterArticles({ language: value[0], project: value[1] });
      } else {
        this.props.filterArticles({ language: null, project: value[0] });
      }
    } else {
      // since the wiki search param is absent, set the URL using the previous
      // filter in the redux store
      const wikiFilterValue = this.wikiObjectToString(this.props.wikiFilter);
      this.updateParams('wiki', wikiFilterValue);
    }

    // filter by "newness"
    if (newness !== undefined) {
      // newness is passed as a search param
      this.props.filterNewness(newness);
    } else {
      // absent, so setting newness from the redux store
      this.updateParams('newness', this.props.newnessFilter);
    }

    // filter by "tracked"
    if (tracked !== undefined) {
      // tracked is passed as a search param
      this.props.filterTrackedStatus(tracked);
    } else {
      // absent, so setting tracked from the redux store
      this.updateParams('tracked', this.props.trackedStatusFilter);
    }
    return {
      selectedIndex: -1,
    };
  },

  componentDidMount() {
    // sets the title for this tab
    const project = this.props.course.home_wiki.project;
    document.title = `${this.props.course.title} - ${ArticleUtils.I18n('edited', project)}`;
  },

  onChangeFilter(e) {
    this.updateParams('wiki', e.target.value);
    const value = e.target.value.split('.');
    if (value.length > 1) {
      return this.props.filterArticles({ language: value[0], project: value[1] });
    }
    return this.props.filterArticles({ language: null, project: value[0] });
  },

  onNewnessChange(e) {
    this.updateParams('newness', e.target.value);
    return this.props.filterNewness(e.target.value);
  },

  onTrackedFilterChange(e) {
    this.updateParams('tracked', e.target.value);
    return this.props.filterTrackedStatus(e.target.value);
  },

  updateParams(filter, value) {
    // instead of using React Router's location, we must use window.location
    // this is because v6 of React Router doesn't have a mutable history object
    // to fix, probably convert this to a functional component with the params as state
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
  },

  showDiff(index) {
    this.setState({
      selectedIndex: index
    });
  },

  showMore() {
    return this.props.fetchArticles(this.props.course_id, this.props.limit + 500);
  },

  sortSelect(e) {
    return this.props.sortArticles(e.value);
  },

  wikiObjectToString(wikiFilter) {
    let wikiFilterValue;

    if (wikiFilter.language) {
      wikiFilterValue = `${wikiFilter.language}.${wikiFilter.project}`;
    } else {
      wikiFilterValue = `${wikiFilter.project}`;
    }
    return wikiFilterValue;
  },

  render() {
    const keys = articleListKeys(this.props.course);
    const project = this.props.course.home_wiki.project;
    const trackedEditable = this.props.current_user && this.props.current_user.isAdvancedRole;

    if (this.props.course.type !== 'ClassroomProgramCourse' && trackedEditable) {
      keys.tracked = {
        label: I18n.t('articles.tracked'),
        desktop_only: true,
        sortable: false,
        info_key: `${ArticleUtils.articlesOrItems(project)}.tracked_doc`
      };
    }

    const sort = this.props.sort;
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
    const articleElements = this.props.articles.map((article, index) => (
      <Article
        article={article}
        index={index}
        showOnMount={showArticleId === article.id}
        course={this.props.course}
        key={article.id}
        wikidataLabel={this.props.wikidataLabels[article.title]}
        // eslint-disable-next-line
        current_user={this.props.current_user}
        fetchArticleDetails={this.props.actions.fetchArticleDetails}
        updateArticleTrackedStatus={this.props.actions.updateArticleTrackedStatus}
        articleDetails={this.props.articleDetails[article.id] || null}
        setSelectedIndex={this.showDiff}
        lastIndex={this.props.articles.length}
        selectedIndex={this.state.selectedIndex}
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
    const wikiFilterValue = this.wikiObjectToString(this.props.wikiFilter);

    if (this.props.wikis.length > 1) {
      const wikiOptions = this.props.wikis.map((wiki) => {
        const wikiString = `${wiki.language ? `${wiki.language}.` : ''}${wiki.project}`;
        return (<option value={wikiString} key={wikiString}>{wikiString}</option>);
      });

      filterWikis = (
        <select
          onChange={this.onChangeFilter}
          value={wikiFilterValue}
        >
          <option value="all">{I18n.t('articles.filter.wiki_all')}</option>
          {wikiOptions}
        </select>
      );
    }

    let filterArticlesSelect;
    if (this.props.newnessFilterEnabled) {
      filterArticlesSelect = (
        <select
          className="filter-articles"
          value={this.props.newnessFilter}
          onChange={this.onNewnessChange}
        >
          <option value="new">{I18n.t('articles.filter.new')}</option>
          <option value="existing">{I18n.t('articles.filter.existing')}</option>
          <option value="both">{I18n.t('articles.filter.new_and_existing')}</option>
        </select>
      );
    }

    let filterTracked;
    if (this.props.trackedStatusFilterEnabled) {
      filterTracked = (
        <select
          className="filter-articles"
          value={this.props.trackedStatusFilter}
          onChange={this.onTrackedFilterChange}
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
          onChange={this.sortSelect}
          name="sorts"
          options={options}
          styles={sortSelectStyles}
        />
      </div>
    );

    const sectionHeader = (
      <div className="section-header">
        {header}
        <CourseOresPlot course={this.props.course} />
        <div className="wrap-filters">
          {filterLabel}
          {filterTracked}
          {filterArticlesSelect}
          {filterWikis}
          <div>{articleSort}</div>
        </div>
      </div>
    );
    const limitReached = this.props.limitReached;
    const showMoreSection = (
      <div className="see-more">
        <PaginatedArticleControls showMore={this.showMore} limitReached={limitReached} />
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
          sortBy={this.props.sortArticles}
        />
      </div>
    );
  }
});

const mapStateToProps = (state) => {
  return ({
    articleDetails: state.articleDetails,
    sort: state.articles.sort,
  });
};

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});


export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ArticleList));
