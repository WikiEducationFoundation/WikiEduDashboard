import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as ArticleActions from '../../actions/article_actions';
import List from '../common/list.jsx';
import Article from './article.jsx';
import CourseOresPlot from './course_ores_plot.jsx';
import articleListKeys from './article_list_keys';
import CourseUtils from '../../utils/course_utils.js';

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
    return {
      selectedIndex: -1,
    };
  },

  onChangeFilter(e) {
    const value = e.target.value.split('.');
    if (value.length > 1) {
      return this.props.filterArticles({ language: value[0], project: value[1] });
    }
    return this.props.filterArticles({ language: null, project: value[0] });
  },

  onNewnessChange(e) {
    return this.props.filterNewness(e.target.value);
  },

  onTrackedFilterChange(e) {
    return this.props.filterTrackedStatus(e.target.value);
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
    return this.props.sortArticles(e.target.value);
  },

  render() {
    const keys = articleListKeys(this.props.course);

    const trackedEditable = this.props.current_user && this.props.current_user.isAdvancedRole;

    if (this.props.course.type !== 'ClassroomProgramCourse' && trackedEditable) {
      keys.tracked = {
        label: I18n.t('articles.tracked'),
        desktop_only: true,
        sortable: false,
        info_key: 'articles.tracked_doc'
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
      />
    ));

    let header;
    if (Features.wikiEd) {
      header = <h3 className="article tooltip-trigger">{I18n.t('metrics.articles_edited')}</h3>;
    } else {
      header = (
        <h3 className="article tooltip-trigger">{I18n.t('metrics.articles_edited')}
          <span className="tooltip-indicator" />
          <div className="tooltip dark">
            <p>{I18n.t('articles.cross_wiki_tracking')}</p>
          </div>
        </h3>
      );
    }

    let filterWikis;
    if (this.props.wikis.length > 1) {
      const wikiOptions = this.props.wikis.map((wiki) => {
        const wikiString = `${wiki.language ? `${wiki.language}.` : ''}${wiki.project}`;
        return (<option value={wikiString} key={wikiString}>{wikiString}</option>);
      });

      filterWikis = (
        <select onChange={this.onChangeFilter}>
          <option value="all">{I18n.t('articles.filter.wiki_all')}</option>
          {wikiOptions}
        </select>
      );
    }

    let filterArticlesSelect;
    if (this.props.newnessFilterEnabled) {
      filterArticlesSelect = (
        <select className="filter-articles" defaultValue="both" onChange={this.onNewnessChange}>
          <option value="new">{I18n.t('articles.filter.new')}</option>
          <option value="existing">{I18n.t('articles.filter.existing')}</option>
          <option value="both">{I18n.t('articles.filter.new_and_existing')}</option>
        </select>
      );
    }

    let filterTracked;
    if (this.props.trackedStatusFilterEnabled) {
      filterTracked = (
        <select className="filter-articles" value={this.props.trackedStatusFilter} onChange={this.onTrackedFilterChange}>
          <option value="tracked">{I18n.t('articles.filter.tracked')}</option>
          <option value="untracked">{I18n.t('articles.filter.untracked')}</option>
          <option value="both">{I18n.t('articles.filter.tracked_and_untracked')}</option>
        </select>
      );
    }

    let filterLabel;
    if (!!filterWikis || !!filterArticlesSelect || !!filterTracked) {
      filterLabel = <b>Filters:</b>;
    }

    const articleSort = (
      <div className="article-sort">
        <select className="sorts" name="sorts" onChange={this.sortSelect}>
          <option value="rating_num">{I18n.t('articles.rating')}</option>
          <option value="title">{I18n.t('articles.title')}</option>
          <option value="character_sum">{I18n.t('metrics.char_added')}</option>
          <option value="references_count">{I18n.t('metrics.references_count')}</option>
          <option value="view_count">{I18n.t('metrics.view')}</option>
        </select>
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
          {articleSort}
        </div>
      </div>
    );

    let showMoreSection;
    if (!this.props.limitReached) {
      showMoreSection = (
        <div className="see-more">
          <button className="button ghost" onClick={this.showMore}>{I18n.t('articles.see_more')}</button>
          <p>{I18n.t('articles.articles_shown', { count: articleElements.length, total: this.props.course.edited_count })}</p>
        </div>
      );
    }

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
          none_message={CourseUtils.i18n('articles_none', this.props.course.string_prefix)}
          sortBy={this.props.sortArticles}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  articleDetails: state.articleDetails,
  sort: state.articles.sort,
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators({ ...ArticleActions }, dispatch)
});


export default connect(mapStateToProps, mapDispatchToProps)(ArticleList);
