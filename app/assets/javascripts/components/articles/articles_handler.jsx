import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import _ from 'lodash';

import ArticleList from './article_list.jsx';
import AssignmentList from '../assignments/assignment_list.jsx';
import AvailableArticles from '../articles/available_articles.jsx';
import CourseOresPlot from './course_ores_plot.jsx';
import CategoryHandler from '../categories/category_handler.jsx';
import ArticlesNavbar from './articles_navbar.jsx';
import ArticleFinder from '../article_finder/article_finder.jsx';

import { fetchArticles, sortArticles, filterArticles } from '../../actions/articles_actions.js';
import { fetchAssignments } from '../../actions/assignment_actions';
import { updateArticlesCurrent } from '../../actions/ui_actions_redux.js';
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

  componentWillMount() {
    if (this.props.loadingAssignments) {
      this.props.fetchAssignments(this.props.course_id);
    }
    if (this.props.loadingArticles) {
      this.props.fetchArticles(this.props.course_id, this.props.limit);
    }
  },

  componentDidMount() {
    return window.addEventListener('scroll', _.throttle(this.handleScroll, 1500));
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

  handleScroll() {
    if (this.refs.articlesEdited && !this.props.articlesUi.scrollDebounce && this.props.articlesUi.articlesCurrent !== 'article-finder') {
        const editedArticles = this.refs.articlesEdited.getBoundingClientRect();
        const assignedArticles = this.refs.articlesAssigned.getBoundingClientRect();
        if (editedArticles.bottom - 100 > 0) {
          return this.props.updateArticlesCurrent('articles-edited');
        } else if (assignedArticles.bottom - 100 > 0) {
          return this.props.updateArticlesCurrent('articles-assigned');
        }
        return this.props.updateArticlesCurrent('available-articles');
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
        <div className="filter-select">
          <select className="filters" name="filters" onChange={this.onChangeFilter}>
            <option value="all">All</option>
            {wikiOptions}
          </select>
        </div>
      );
    }

    return (
      <div className="articles-content">
        <div>
          <div className={`articles-list ${this.props.articlesUi.articlesCurrent === 'article-finder' ? 'hidden' : ''}`}>
            <div id="articles" ref="articlesEdited">
              <a id="articles-edited" className="articles__anchor" />
              <div className="section-header">
                {header}
                <CourseOresPlot course={this.props.course} />
                {filterWikis}
                <div className="sort-select">
                  <select className="sorts" name="sorts" onChange={this.sortSelect}>
                    <option value="rating_num">{I18n.t('articles.rating')}</option>
                    <option value="title">{I18n.t('articles.title')}</option>
                    <option value="character_sum">{I18n.t('metrics.char_added')}</option>
                    <option value="view_count">{I18n.t('metrics.view')}</option>
                  </select>
                </div>
              </div>
              <ArticleList
                articles={this.props.articles}
                sortBy={this.props.sortArticles}
                course={this.props.course}
                current_user={this.props.current_user}
                wikidataLabels={this.props.wikidataLabels}
              />
              {showMoreButton}
            </div>
            <div id="assignments" ref="articlesAssigned">
              <a id="articles-assigned" className="articles__anchor" />
              <div className="section-header">
                <h3>{I18n.t('articles.assigned')}</h3>
              </div>
              <AssignmentList
                articles={this.props.articles}
                assignments={this.props.assignments}
                course={this.props.course}
                current_user={this.props.current_user}
                wikidataLabels={this.props.wikidataLabels}
              />
            </div>
            <div ref="availableArticles">
              <a id="available-articles" className="articles__anchor" />
              <AvailableArticles
                course_id={this.props.course_id}
                course={this.props.course}
                current_user={this.props.current_user}
                assignments={this.props.assignments}
              />
            </div>
            {categories}
          </div>
          <div className={`articles-list ${this.props.articlesUi.articlesCurrent !== 'article-finder' ? 'hidden' : ''}`}>
            <ArticleFinder
              course_id={this.props.course_id}
              current_user={this.props.current_user}
              course={this.props.course}
            />
          </div>
        </div>
        <ArticlesNavbar
          current_user={this.props.current_user}
          course_id={this.props.course_id}
          toggleDebounce={this.toggleDebounce}
        />
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
  loadingAssignments: state.assignments.loading,
  articlesUi: state.ui.articles,
});

const mapDispatchToProps = {
  fetchArticles,
  sortArticles,
  filterArticles,
  fetchAssignments,
  updateArticlesCurrent,
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticlesHandler);
