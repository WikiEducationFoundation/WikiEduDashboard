import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import InputRange from 'react-input-range';

import TextInput from '../common/text_input.jsx';
import ArticleFinderRow from './article_finder_row.jsx';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

import { fetchCategoryResults, fetchKeywordResults, updateFields, sortArticleFinder } from '../../actions/article_finder_action.js';
import { fetchAssignments, addAssignment } from '../../actions/assignment_actions.js';
import { getFilteredArticleFinder } from '../../selectors';

const ArticleFinder = createReactClass({
  getInitialState() {
    return {
      isSubmitted: false,
    };
  },

  componentWillMount() {
    if (this.props.course_id && this.props.loadingAssignments) {
      return this.props.fetchAssignments(this.props.course_id);
    }
  },

  updateFields(key, value) {
    return this.props.updateFields(key, value);
  },

  searchArticles() {
    this.setState({
      isSubmitted: true,
    });
    if (this.props.search_type === 'keyword') {
      return this.props.fetchKeywordResults(this.props.search_term);
    }
    return this.props.fetchCategoryResults(this.props.search_term);
  },

  fetchMoreResults() {
    if (this.props.search_type === 'keyword') {
      return this.props.fetchKeywordResults(this.props.search_term, this.props.offset, true);
    }
    return this.props.fetchCategoryResults(this.props.search_term, this.props.cmcontinue, true);
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
        label={I18n.t('article_finder.category')}
        placeholder={I18n.t('article_finder.category')}
      />);

    const searchType = (
      <div>
        <div>
          <label>
            <input type="radio" value="category" checked={this.props.search_type === "category"} onChange={(e) => this.updateFields("search_type", e.target.value)} />
            Category Based Search
          </label>
        </div>
        <div>
          <label>
            <input type="radio" value="keyword" checked={this.props.search_type === "keyword"} onChange={(e) => this.updateFields("search_type", e.target.value)} />
            Keyword Based Search
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
        <label className="mb2">Article Quality(0-100)</label>
        <InputRange
          maxValue={100}
          minValue={0}
          value={this.props.article_quality}
          onChange={value => this.updateFields('article_quality', value)}
          step={1}
        />
      </div>
      );

    const filters = (
      <div className="form-container mb2">
        <h4>Filter your results:</h4>
        <div className="horizontal-form">
          {minimumViews}
          {articleQuality}
        </div>
      </div>
    );

    const keys = {
      title: {
        label: I18n.t('articles.title'),
        desktop_only: false
      },
      grade: {
        label: I18n.t('article_finder.page_assessment_grade'),
        desktop_only: false,
      },
      revScore: {
        label: I18n.t('article_finder.completeness_estimate'),
        desktop_only: false,
      },
      pageviews: {
        label: I18n.t('article_finder.average_views'),
        desktop_only: false,
      },
    };

    let list;
    if (this.state.isSubmitted && !this.props.loading) {
      const elements = _.map(this.props.articles, (article, title) => {
        const isAdded = Boolean(_.find(this.props.assignments, { article_title: title }));
        return (
          <ArticleFinderRow
            article={article}
            title={title}
            key={article.pageid}
            courseSlug={this.props.course_id}
            course={this.props.course}
            isAdded={isAdded}
            addAssignment={this.props.addAssignment}
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
      fetchMoreButton = (<button className="button dark text-center" onClick={this.fetchMoreResults}>More Results</button>);
    }

    return (
      <div className="container">
        <header>
          <h1 className="title">Article Finder</h1>
          <div>
            Let&#39;s find an article which fits your needs.
          </div>
        </header>
        <div className="article-finder-form">
          {searchTerm}
          {searchType}
          <div className="text-center">
            <button className="button dark" onClick={this.searchArticles}>Submit</button>
          </div>
        </div>
        {filters}
        {loader}
        {list}
        {fetchMoreButton}
      </div>
      );
  }
});

const mapStateToProps = state => ({
  articles: getFilteredArticleFinder(state),
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
});

const mapDispatchToProps = {
  fetchCategoryResults: fetchCategoryResults,
  updateFields: updateFields,
  addAssignment: addAssignment,
  fetchAssignments: fetchAssignments,
  sortArticleFinder: sortArticleFinder,
  fetchKeywordResults: fetchKeywordResults,
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticleFinder);
