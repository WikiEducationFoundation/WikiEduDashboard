import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";
import Select from 'react-select';

import { initiateConfirm } from '../../actions/confirm_actions';
import TextInput from '../common/text_input';
import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
import CourseUtils from '../../utils/course_utils.js';

const AddCategoryButton = createReactClass({
  displayName: 'AddCategoryButton',

  propTypes: {
    course: PropTypes.object.isRequired,
    is_open: PropTypes.bool,
    open: PropTypes.func.isRequired,
    initiateConfirm: PropTypes.func,
    addCategory: PropTypes.func
  },

  getInitialState() {
    return ({
      category: '',
      language: this.props.course.home_wiki.language,
      project: this.props.course.home_wiki.project,
      depth: 0,
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
      course: this.props.course
    };

    if (categoryCourse.category === '' || categoryCourse.category === 'undefined') {
      return;
    } else if (categoryCourse.category.length > 255) {
      // Title shouldn't exceed 255 chars to prevent mysql errors
      alert(I18n.t('assignments.title_too_large'));
      return;
    }

    // Close the popup after adding an available article
    const closePopup = this.props.open;

    const addCategory = this.props.addCategory;
    const onConfirm = function () {
      // Post the new category to the server
      addCategory(categoryCourse);
      closePopup(e);
    };

    const confirmMessage = I18n.t('categories.confirm_addition', { category: categoryCourse.category });
    console.log('initiate confirm')
    return this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  render() {
    const permitted = true;
    let className = 'button border small assign-button';
    if (this.props.is_open) { className += ' dark'; }

    const buttonText = I18n.t('categories.add_category');
    const showButton = <button className={`${className}`} onClick={this.props.open}>{buttonText}</button>;

    let editRow;
    if (permitted) {
      let options;
      if (this.state.showOptions) {
        const languageOptions = JSON.parse(WikiLanguages).map(language => {
          return { label: language, value: language };
        });

        const projectOptions = JSON.parse(WikiProjects).map(project => {
          return { label: project, value: project };
        });

        options = (
          <fieldset className="mt1">
            <Select
              ref="languageSelect"
              className="half-width-select-left language-select"
              name="language"
              placeholder="Language"
              onChange={this.handleChangeLanguage}
              value={this.state.language}
              options={languageOptions}
            />
            <Select
              name="project"
              ref="projectSelect"
              className="half-width-select-right project-select"
              onChange={this.handleChangeProject}
              placeholder="Project"
              value={this.state.project}
              options={projectOptions}
            />
          </fieldset>
        );
      } else {
        options = (
          <div className="small-block-link">
            {this.state.language}.{this.state.project}.org <a href="#" onClick={this.handleShowOptions}>({I18n.t('application.change')})</a>
          </div>
        );
      }

      editRow = (
        <tr className="edit">
          <td>
            <form onSubmit={this.addCategory}>
              <input value={this.state.category} onChange={this.handleChangeCategory} type="text" ref="category" placeholder={I18n.t('categories.placeholder')} />
              <button className="button border" type="submit">{I18n.t('categories.add_this_category')}</button>
              {options}
            </form>
          </td>
        </tr>
      );
    }

    return (
      <div className="pop__container">
        {showButton}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRow}
        />
      </div>
    );
  }
});

const mapDispatchToProps = { initiateConfirm };

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(AddCategoryButton)
);
