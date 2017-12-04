import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";

import { initiateConfirm } from '../../actions/confirm_actions';
import TextInput from '../common/text_input';
import PopoverExpandable from '../high_order/popover_expandable.jsx';

const AddCategoryButton = createReactClass({
  displayName: 'AddCategoryButton',

  getInitialState() {
    return ({
      category: '',
      language: this.props.course.home_wiki.language,
      project: this.props.course.home_wiki.project,
      showOptions: false
    });
  },

  getKey() {
    return 'add_category_button';
  },

  handleChangeCategory(e) {
    e.preventDefault();
    const categoryInput = e.target.value;
    const page = CourseUtils.articleFromTitleInput(categoryInput);
    const language = page.language ? page.language : this.state.language;
    const project = page.project ? page.project : this.state.project;
    return this.setState({
      category: page.title,
      project,
      language
    });
  },

  handleShowOptions(e) {
    e.preventDefault();
    return this.setState(
      { showOptions: true });
  },

  handleChangeLanguage(val) {
    return this.setState(
      { language: val.value });
  },

  handleChangeProject(val) {
    return this.setState(
      { project: val.value });
  },

  addCategory(e) {
    e.preventDefault();

    const categoryCourse = {
      category: decodeURIComponent(this.state.category).trim(),
      project: this.state.project,
      language: this.state.language,
      depth: this.state.depth,
      course_id: this.props.course_id
    };

    if (categoryCourse.title === '' || categoryCourse.title === 'undefined') {
      return;
    } else if (assignment.title.length > 255) {
      // Title shouldn't exceed 255 chars to prevent mysql errors
      alert(I18n.t('assignments.title_too_large'));
      return;
    }

    // Close the popup after adding an available article
    const closePopup = this.props.open;

    const onConfirm = function () {
      // Close the popup after confirmation
      if (closeOnConfirm) {
        closePopup(e);
      }
      // Post the new category to the server
      this.props.addCategory(categoryCourse);
    };

    const confirmMessage = I18n.t('categories.confirm_addition', { category: articleTitle });

    return this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  render() {
    let className = 'button border small assign-button';
    if (this.props.is_open) { className += ' dark'; }

    const buttonText = 'Ohai';
    const showButton = <button className={`${className}`} onClick={this.props.open}>{buttonText}</button>;

    return (
      <div>
        {showButton}
      </div>
    );
  }
});

const mapDispatchToProps = dispatch => ({ initiateConfirm });

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(AddCategoryButton)
);
