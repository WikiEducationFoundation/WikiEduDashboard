import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import { connect } from "react-redux";

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Lookup from '../common/lookup.jsx';
import { initiateConfirm } from '../../actions/confirm_actions';
import ServerActions from '../../actions/server_actions.js';
import AssignmentActions from '../../actions/assignment_actions.js';
import AssignmentStore from '../../stores/assignment_store.js';
import CourseUtils from '../../utils/course_utils.js';

const AssignButton = createReactClass({
  displayName: 'AssignButton',

  propTypes: {
    course: PropTypes.object.isRequired,
    role: PropTypes.number.isRequired,
    student: PropTypes.object,
    current_user: PropTypes.object,
    course_id: PropTypes.string.isRequired,
    is_open: PropTypes.bool,
    permitted: PropTypes.bool,
    add_available: PropTypes.bool,
    assignments: PropTypes.array,
    open: PropTypes.func.isRequired,
    tooltip_message: PropTypes.string,
    initiateConfirm: PropTypes.func
  },

  getInitialState() {
    return ({
      showOptions: false,
      language: this.props.course.home_wiki.language,
      project: this.props.course.home_wiki.project,
      title: ''
    });
  },

  getKey() {
    const tag = this.props.role === 0 ? 'assign_' : 'review_';
    if (this.props.student) {
      return tag + this.props.student.id;
    }
    return tag;
  },

  resetState() {
    return this.setState(this.getInitialState());
  },

  stop(e) {
    return e.stopPropagation();
  },


  handleShowOptions(e) {
    e.preventDefault();
    return this.setState(
      { showOptions: true });
  },

  handleChangeTitle(e) {
    e.preventDefault();
    const title = e.target.value;
    const assignment = CourseUtils.articleFromTitleInput(title);
    const language = assignment.language ? assignment.language : this.state.language;
    const project = assignment.project ? assignment.project : this.state.project;
    return this.setState({
      title: assignment.title,
      project,
      language
    });
  },
  handleChangeLanguage(val) {
    return this.setState(
      { language: val.value });
  },
  handleChangeProject(val) {
    return this.setState(
      { project: val.value });
  },

  assign(e) {
    e.preventDefault();

    let student;
    if (this.props.student) {
      student = this.props.student.id;
    } else {
      student = null;
    }

    const assignment = {
      title: decodeURIComponent(this.state.title).trim(),
      project: this.state.project,
      language: this.state.language,
      course_id: this.props.course_id,
      user_id: student,
      role: this.props.role
    };

    if (assignment.title === '' || assignment.title === 'undefined') {
      return;
    } else if (assignment.title.length > 255) {
      // Title shouldn't exceed 255 chars to prevent mysql errors
      alert(I18n.t('assignments.title_too_large'));
      return;
    }

    const articleTitle = assignment.title;

    // Check if the assignment exists
    if (this.props.student && AssignmentStore.getFiltered({
      articleTitle,
      user_id: this.props.student.id,
      role: this.props.role
    }).length !== 0) {
      alert(I18n.t('assignments.already_exists'));
      return;
    }

    // Close the popup after adding an available article
    const closePopup = this.props.open;
    // While adding other assignments, popup can remain open to assign multiple assignments at once
    const closeOnConfirm = this.props.add_available;

    const onConfirm = function () {
      // Close the popup after confirmation
      if (closeOnConfirm) {
        closePopup(e);
      }
      // Update the store
      AssignmentActions.addAssignment(assignment);
      // Post the new assignment to the server
      ServerActions.addAssignment(assignment);
    };

    let confirmMessage;
    // Confirm for assigning an article to a student
    if (this.props.student) {
      confirmMessage = I18n.t('assignments.confirm_addition', {
        title: articleTitle,
        username: this.props.student.username
      });
    // Confirm for adding an unassigned available article
    } else {
      confirmMessage = I18n.t('assignments.confirm_add_available', {
        title: articleTitle
      });
    }
    return this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  unassign(assignment) {
    if (!confirm(I18n.t('assignments.confirm_deletion'))) { return; }
    // Update the store
    AssignmentActions.deleteAssignment(assignment);
    // Send the delete request to the server
    return ServerActions.deleteAssignment(assignment);
  },

  render() {
    let className = 'button border small assign-button';
    if (this.props.is_open) { className += ' dark'; }

    let showButton;
    let editButton;
    let tooltip;
    let tooltipIndicator;
    if (this.props.assignments.length > 1 || (this.props.assignments.length > 0 && this.props.permitted)) {
      let buttonText;
      if (this.props.is_open) {
        buttonText = I18n.t('users.assign_articles_done');
      } else if (this.props.permitted) {
        buttonText = '+/-';
      } else {
        buttonText = '…';
      }

      showButton = <button className={`${className}`} onClick={this.props.open}>{buttonText}</button>;
    } else if (this.props.permitted) {
      let assignText;
      let reviewText;
      if (this.props.add_available) {
        assignText = I18n.t('assignments.add_available');
      } else if (this.props.student && this.props.current_user.id === this.props.student.id) {
        assignText = I18n.t('assignments.assign_self');
        reviewText = I18n.t('assignments.review_self');
      } else if (this.props.current_user.role > 0 || this.props.current_user.admin) {
        assignText = I18n.t('assignments.assign_other');
        reviewText = I18n.t('assignments.review_other');
      }
      const finalText = this.props.role === 0 ? assignText : reviewText;
      if (this.props.tooltip_message && !this.props.is_open) {
        tooltipIndicator = (
          <span className="tooltip-indicator" />
          );
        tooltip = (
          <div className="tooltip">
            <p>
              {this.props.tooltip_message}
            </p>
          </div>
      );
      }
      editButton = (
        <div className="tooltip-trigger">
          <button className={className} onClick={this.props.open}>{finalText} {tooltipIndicator}</button>
          {tooltip}
        </div>
      );
    }

    let assignments = this.props.assignments.map(ass => {
      let removeButton;
      let articleLink;
      ass.course_id = this.props.course_id;
      const article = CourseUtils.articleFromAssignment(ass, this.props.course.home_wiki);
      if (this.props.permitted) {
        removeButton = <button className="button border plus" onClick={this.unassign.bind(this, ass)}>-</button>;
      }
      if (article.url) {
        articleLink = <a href={article.url} target="_blank" className="inline">{article.formatted_title}</a>;
      } else {
        articleLink = <span>{article.formatted_title}</span>;
      }
      return (
        <tr key={ass.id}>
          <td>{articleLink}{removeButton}</td>
        </tr>
      );
    });

    if (this.props.assignments.length === 0 && this.props.student) {
      assignments = <tr><td>{I18n.t('assignments.none_short')}</td></tr>;
    }

    let editRow;
    if (this.props.permitted) {
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
            <form onSubmit={this.assign}>
              <Lookup
                model="article"
                placeholder={I18n.t('articles.title_example')}
                ref="lookup"
                value={this.state.title}
                onSubmit={this.assign}
                onChange={this.handleChangeTitle}
                disabled={true}
              />
              <button className="button border" type="submit">{I18n.t('assignments.label')}</button>
              {options}
            </form>
          </td>
        </tr>
      );
    }

    return (
      <div className="pop__container" onClick={this.stop}>
        {showButton}
        {editButton}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRow}
          rows={assignments}
        />
      </div>
    );
  }
}
);

const mapDispatchToProps = { initiateConfirm };

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(AssignButton)
);
