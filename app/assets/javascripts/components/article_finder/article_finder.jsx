import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';

import TextInput from '../common/text_input.jsx';
import ArticleFinderRow from './article_finder_row.jsx';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

import { fetchCategoryResults, updateFields } from '../../actions/article_finder_action.js';
import { fetchAssignments, addAssignment } from '../../actions/assignment_actions.js';
import { getFilteredArticleFinder } from '../../selectors';

const ArticleFinder = createReactClass({
  getInitialState() {
    return {
      isSubmitted: false,
    };
  },

  componentWillMount() {
    if (this.props.course_id) {
      return this.props.fetchAssignments(this.props.course_id);
    }
  },

  updateFields(key, value) {
    return this.props.updateFields(key, value);
  },

  searchCategory() {
    this.setState({
      isSubmitted: true,
    });
    return this.props.fetchCategoryResults(this.props.category, this.props.depth);
  },

  handleChange(e) {
    const grade = e.target.value;
    return this.props.updateFields("grade", grade);
  },

  render() {
    const category = (
      <TextInput
        id="category"
        onChange={this.updateFields}
        value={this.props.category}
        value_key="category"
        required
        editable
        label="Category"
        placeholder="Category"
      />);
    const depth = (
      <TextInput
        id="depth"
        onChange={this.updateFields}
        value={this.props.depth}
        value_key="depth"
        required
        editable
        label="Depth"
        placeholder="Depth"
      />);
    const minimumViews = (
      <TextInput
        id="min_views"
        onChange={this.updateFields}
        value={this.props.min_views}
        value_key="min_views"
        required
        editable
        label="Minimum Views"
        placeholder="Minimum Views"
      />);
    const maxCompleteness = (
      <TextInput
        id="max_completeness"
        onChange={this.updateFields}
        value={this.props.max_completeness}
        value_key="max_completeness"
        required
        editable
        label="Max Completeness(0-100)"
        placeholder="Completeness"
      />);
    const grade = (
      <select
        id="grade_selector"
        name="grade_value"
        value={this.props.grade}
        onChange={this.handleChange}
      >
        <option disabled value=""> — select one —</option>
        <option value="FA">FA</option>
        <option value="GA">GA</option>
        <option value="B">B</option>
        <option value="C">C</option>
        <option value="Start">Start</option>
        <option value="Stub">Stub</option>
      </select>);
    const keys = {
      title: {
        label: I18n.t('articles.title'),
        desktop_only: false
      },
      pageassessment_grade: {
        label: 'PageAssessment Grade',
        desktop_only: false,
      },
      completeness_estimate: {
        label: 'Completeness Estimate',
        desktop_only: false,
      },
      average_views: {
        label: 'Views per day',
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
          sortable={false}
          table_key="category-articles"
          className="table--expandable table--hoverable"
          none_message="No articles found in this category"
        />
        );
    }
    let loader;
    if (this.state.isSubmitted && this.props.loading) {
      loader = <Loading />;
    }

    return (
      <div className="container">
        <header>
          <h1 className="title">Article Finder</h1>
          <div>
            Let&#39;s find an article which fits your needs.
          </div>
        </header>
        {category}
        {depth}
        {minimumViews}
        {maxCompleteness}
        {grade}
        <button className="button dark" onClick={this.searchCategory}>Submit</button>
        {loader}
        {list}
      </div>
      );
  }
});

const mapStateToProps = state => ({
  articles: getFilteredArticleFinder(state),
  loading: state.articleFinder.loading,
  category: state.articleFinder.category,
  min_views: state.articleFinder.min_views,
  grade: state.articleFinder.grade,
  max_completeness: state.articleFinder.max_completeness,
  depth: state.articleFinder.depth,
  assignments: state.assignments.assignments,
});

const mapDispatchToProps = {
  fetchCategoryResults: fetchCategoryResults,
  updateFields: updateFields,
  addAssignment: addAssignment,
  fetchAssignments: fetchAssignments
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticleFinder);
