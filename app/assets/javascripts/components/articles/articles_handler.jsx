import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';

import ArticleList from './article_list.jsx';
import AssignmentList from '../assignments/assignment_list.jsx';
import AvailableArticles from '../articles/available_articles.jsx';
import CourseOresPlot from './course_ores_plot.jsx';
import CategoryHandler from '../categories/category_handler.jsx';
import { fetchArticles, sortArticles, filterArticles } from '../../actions/articles_actions.js';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getWikiArticles } from '../../selectors';

const ArticlesHandler = createReactClass({
  displayName: 'ArticlesHandler',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    course: PropTypes.object,
    fetchArticles: PropTypes.func,
    limitReached: PropTypes.bool,
    limit: PropTypes.number,
    articles: PropTypes.array,
    loadingArticles: PropTypes.bool,
    assignments: PropTypes.array,
    loadingAssignments: PropTypes.bool
  },

  getInitialState() {
    return { filter: 'both' };
  },

  componentWillMount() {
    if (this.props.loadingAssignments) {
      this.props.fetchAssignments(this.props.course_id);
    }
    if (this.props.loadingArticles) {
      this.props.fetchArticles(this.props.course_id, this.props.limit);
    }
  },

  onChangeFilter(e) {
    const value = e.target.value.split('.');
    if (value.length > 1) {
      return this.props.filterArticles({ language: value[0], project: value[1] });
    }
    return this.props.filterArticles({ language: null, project: value[0] });
  },

  showMore() {
    return this.props.fetchArticles(this.props.course_id, this.props.limit + 500);
  },

  sortSelect(e) {
    return this.props.sortArticles(e.target.value);
  },

  filterSelect(e) {
    this.setState({ filter: e.target.value });
  },

  filterArticles() {
    switch (this.state.filter) {
      case 'new':
        return this.props.articles.filter(a => a.new_article);
      case 'existing':
        return this.props.articles.filter(a => !a.new_article);
      default:
        return this.props.articles;
    }
  },

  render() {
    // FIXME: These props should be required, and this component should not be
    // mounted in the first place if they are not available.
    if (!this.props.course || !this.props.course.home_wiki) { return <div />; }

    let showMoreButton;
    if (!this.props.limitReached) {
      showMoreButton = <div><button className="button ghost stacked right" onClick={this.showMore}>{I18n.t('articles.see_more')}</button></div>;
    }

    let header;
    if (Features.wikiEd) {
      header = <h3 className="tooltip-trigger">{I18n.t('metrics.articles_edited')}</h3>;
    } else {
      header = (
        <h3 className="tooltip-trigger">{I18n.t('metrics.articles_edited')}
          <span className="tooltip-indicator" />
          <div className="tooltip dark">
            <p>{I18n.t('articles.cross_wiki_tracking')}</p>
          </div>
        </h3>
      );
    }

    let categories;
    if (this.props.course.type === 'ArticleScopedProgram') {
      categories = <CategoryHandler course={this.props.course} current_user={this.props.current_user} />;
    }

    let filterWikis;
    if (this.props.wikis.length > 1) {
      const wikiOptions = this.props.wikis.map((wiki) => {
        const wikiString = `${wiki.language ? `${wiki.language}.` : ''}${wiki.project}`;
        return (<option value={wikiString} key={wikiString}>{wikiString}</option>);
      });

      filterWikis = (
        <select onChange={this.onChangeFilter}>
          <option value="all">All</option>
          {wikiOptions}
        </select>
      );
    }

    const filterArticlesSelect = (
      <select className="filter-articles" defaultValue="both" onChange={this.filterSelect}>
        <option value="new">New</option>
        <option value="existing">Existing</option>
        <option value="both">New and existing</option>
      </select>
    );
    const filteredArticles = this.filterArticles();

    let filterLabel;
    if (!!filterWikis || !!filterArticlesSelect) {
      filterLabel = <b>Filters:</b>;
    }
    return (
      <div>
        <div id="articles">
          <div className="section-header">
            {header}
            <CourseOresPlot course={this.props.course} />
            <div className="wrap-filters">
              {filterLabel}
              {filterArticlesSelect}
              {filterWikis}
              <div className="article-sort">
                <select className="sorts" name="sorts" onChange={this.sortSelect}>
                  <option value="rating_num">{I18n.t('articles.rating')}</option>
                  <option value="title">{I18n.t('articles.title')}</option>
                  <option value="character_sum">{I18n.t('metrics.char_added')}</option>
                  <option value="view_count">{I18n.t('metrics.view')}</option>
                </select>
              </div>
            </div>
          </div>
          <ArticleList {...this.props} articles={filteredArticles} sortBy={this.props.sortArticles} />
          {showMoreButton}
        </div>
        <div id="assignments" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.assigned')}</h3>
          </div>
          <AssignmentList {...this.props} />
        </div>
        <AvailableArticles {...this.props} />
        {categories}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  limit: state.articles.limit,
  articles: getWikiArticles(state),
  limitReached: state.articles.limitReached,
  wikis: state.articles.wikis,
  wikidataLabels: state.wikidataLabels.labels,
  loadingArticles: state.articles.loading,
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading
});

const mapDispatchToProps = {
  fetchArticles,
  sortArticles,
  filterArticles,
  fetchAssignments
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticlesHandler);
