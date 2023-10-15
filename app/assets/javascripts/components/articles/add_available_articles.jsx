import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextAreaInput from '../common/text_area_input';
import CourseUtils from '../../utils/course_utils.js';
import ArticleUtils from '../../utils/article_utils';
import { connect } from 'react-redux';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import API from '../../utils/api';

const AddAvailableArticles = createReactClass({
  displayName: 'AddAvailableArticles',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    role: PropTypes.number.isRequired,
    current_user: PropTypes.object,
    assignments: PropTypes.array,
    project: PropTypes.string,
    language: PropTypes.string,
    addAssignment: PropTypes.func,
    open: PropTypes.func // closes popover
  },

  getInitialState() {
    return { assignments: '' };
  },

  updateInput(_key, value) {
    return this.setState({ assignments: value });
  },

  resetInput() {
    this.setState({ assignments: '' });
    this.props.open();
  },

  chainSubmissions(assignments, promise) {
    const assignment = assignments.shift();
    if (assignment === undefined) { return promise; }
    let extendedPromise;
    if (promise) {
      extendedPromise = promise.then(() => this.props.addAssignment(assignment));
    } else {
      extendedPromise = this.props.addAssignment(assignment);
    }
    return this.chainSubmissions(assignments, extendedPromise);
  },

   async submit() {
    // Split multiline input into an array of lines, trim whitespace, and filter out empty lines
    const inputLines = this.state.assignments.match(/[^\r\n]+/g).map(item => item.trim()).filter(Boolean);
    const assignments = inputLines.map((assignmentString) => {
      const assignment = CourseUtils.articleFromTitleInput(assignmentString);
      const language = assignment.language ? assignment.language : this.props.language;
      const project = assignment.project ? assignment.project : this.props.project;
      return {
        title: assignment.title,
        project,
        language,
        course_slug: this.props.course_id,
        role: this.props.role
      };
    });

    // Check if any article/assignment title is under a particular wikipedia category
    const categoryMembers = await API.checkArticleInWikiCategory(assignments.map(assignment => assignment.title));
    const isArticleInCategory = categoryMembers.length > 0;

    const addAssignment = () => {
      return this.chainSubmissions(assignments)
        .then(() => this.resetInput());
    };

    // If article/assignment is a member of discouraged category in wikipedia
    // display a message  to confirm if the user wants to add the assignment.
    if (isArticleInCategory) {
      const confirmMessage = I18n.t('articles.discouraged_article', {
        type: 'Assigning',
        action: 'assign',
        article: categoryMembers.length > 1 ? 'articles' : 'article',
        article_list: categoryMembers.join(', '),
      });
      this.props.initiateConfirm({ confirmMessage, onConfirm: addAssignment });
    } else {
      addAssignment();
    }
  },

  render() {
    const isWikidata = this.props.project === 'wikidata';
    const inputId = isWikidata ? 'add_available_items' : 'add_available_articles';
    const inputPlaceholder = isWikidata ? I18n.t('assignments.add_available_placeholder_wikidata') : I18n.t('assignments.add_available_placeholder');
    return (
      <div className="pop__padded-content">
        <TextAreaInput
          id={inputId}
          onChange={this.updateInput}
          value={this.state.assignments}
          value_key="assignments"
          editable
          placeholder={inputPlaceholder}
        />
        <button className="button border pull-right" onClick={this.submit}>{I18n.t(`assignments.${ArticleUtils.projectSuffix(this.props.project, 'add_available_submit')}`)}</button>
      </div>
    );
  }
});

const mapDispatchToProps = {
 initiateConfirm
};

export default connect(null, mapDispatchToProps)(AddAvailableArticles);
