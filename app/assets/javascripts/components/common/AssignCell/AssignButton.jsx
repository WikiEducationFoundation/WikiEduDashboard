import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';

import PopoverExpandable from '../../high_order/popover_expandable.jsx';
import Popover from '../popover.jsx';
import { initiateConfirm } from '../../../actions/confirm_actions';
import { addAssignment, deleteAssignment, claimAssignment } from '../../../actions/assignment_actions';
import CourseUtils from '../../../utils/course_utils.js';
import AddAvailableArticles from '../../articles/add_available_articles';
import NewAssignmentInput from '../../assignments/new_assignment_input';
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '~/app/assets/javascripts/constants';
import SelectedWikiOption from '../selected_wiki_option';
import { trackedWikisMaker } from '../../../utils/wiki_utils';
import ArticleUtils from '../../../utils/article_utils';

// Helper Components
// Button to show the static list
const ShowButton = ({ is_open, open }) => {
  let buttonText = '…';
  if (is_open) buttonText = I18n.t('users.assign_articles_done');

  return (
    <button
      className={`button border small assign-button ${is_open ? 'dark' : ''}`}
      onClick={open}
    >
      {buttonText}
    </button>
  );
};

const AddAssignmentButton = ({ assignment, assign, reviewing = false }) => {
  const text = reviewing ? 'Review' : 'Select';
  return (
    <span>
      <button
        aria-label="Add"
        className="button border assign-selection-button"
        onClick={e => assign(e, assignment)}
      >
        { text }
      </button>
    </span>
  );
};

const RemoveAssignmentButton = ({ assignment, unassign }) => {
  return (
    <span>
      <button
        aria-label="Remove"
        className="button border assign-selection-button"
        onClick={() => unassign(assignment)}
      >
        Remove
      </button>
    </span>
  );
};

const ArticleLink = ({ articleUrl, title }) => {
  if (!articleUrl) return (<span>{ title }</span>);
  return (
    <a href={articleUrl} target="_blank" className="inline" aria-label={`View ${title} on Wikipedia`}>{title}</a>
  );
};

const getArticle = (assignment, course, labels) => {
  const article = CourseUtils.articleFromAssignment(assignment, course.home_wiki);
  const label = labels[article.title];
  article.title = CourseUtils.formattedArticleTitle(article, course.home_wiki, label);

  return article;
};

const AssignedAssignmentRows = ({
  assignments = [], course, permitted, role, wikidataLabels, project, unassign // functions
}) => {
  const elements = assignments.map((assignment) => {
    const article = getArticle(assignment, course, wikidataLabels);

    return (
      <tr key={assignment.id} className="assignment">
        <td>
          <ArticleLink articleUrl={article.url} title={article.title} />
          {
            permitted
            && <RemoveAssignmentButton
              assignment={assignment}
              unassign={unassign}
            />
          }
        </td>
      </tr>
    );
  });

  const text = role === ASSIGNED_ROLE
    ? I18n.t(`courses.assignment_headings.${ArticleUtils.projectSuffix(project, 'assigned_articles')}`)
    : I18n.t('courses.assignment_headings.assigned_reviews');
  const title = (
    <tr key="assigned" className="assignment-section-header">
      <td>
        <h3>{ text }</h3>
      </td>
    </tr>
  );
  return elements.length ? [title].concat(elements) : [];
};

const PotentialAssignmentRows = ({
  assignments = [], course, permitted, role, wikidataLabels,
  assign, // functions
  project
}) => {
  const elements = assignments.map((assignment) => {
    const article = getArticle(assignment, course, wikidataLabels);

    return (
      <tr key={assignment.id} className="assignment">
        <td>
          <ArticleLink articleUrl={article.url} title={article.title} />
          {
            permitted
            && <AddAssignmentButton
              assignment={assignment}
              assign={assign}
              reviewing={role === REVIEWING_ROLE}
            />
          }
        </td>
      </tr>
    );
  });

  const text = role === ASSIGNED_ROLE
    ? I18n.t(`courses.assignment_headings.${ArticleUtils.projectSuffix(project, 'available_articles')}`)
    : CourseUtils.i18n(`assignment_headings.${ArticleUtils.projectSuffix(project, 'available_reviews')}`, course.string_prefix);
  const title = (
    <tr key="available" className="assignment-section-header">
      <td>
        <h3>{ text }</h3>
      </td>
    </tr>
  );
  return elements.length ? [title].concat(elements) : [];
};

const Tooltip = ({ message }) => {
  return (
    <div className="tooltip">
      <p>
        {message}
      </p>
    </div>
  );
};

// Button to add new assignments
const EditButton = ({
  allowMultipleArticles, current_user, is_open, open, role, student,
  tooltip, tooltipIndicator, assignmentLength, project
}) => {
  let assignText;
  let reviewText;
  if (allowMultipleArticles) {
    assignText = I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'add_available')}`);
  } else if (assignmentLength) {
    assignText = '+/-';
    reviewText = '+/-';
  } else if (student && current_user.id === student.id) {
    assignText = I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'assign_self')}`);
    reviewText = I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'review_self')}`);
  } else if (current_user.role > 0 || current_user.admin) {
    assignText = I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'assign_other')}`);
    reviewText = I18n.t('assignments.review_other');
  }

  let finalText = role === ASSIGNED_ROLE ? assignText : reviewText;
  if (is_open) finalText = I18n.t('users.assign_articles_done');

  return (
    <div className="tooltip-trigger">
      <button
        className={`button border small assign-button ${is_open ? 'dark' : ''}`}
        onClick={open}
      >
        {finalText} {tooltipIndicator}
      </button>
      {tooltip}
    </div>
  );
};

const FindArticles = ({ course, open, project, language }) => {
  const btnText = project === 'wikidata' ? I18n.t('items.search') : I18n.t('articles.search');
  return (
    <tr className="assignment find-articles-section">
      <td>
        <Link to={{ pathname: `/courses/${course.slug}/article_finder`, project: `${project}`, language: `${language}` }}>
          <button className="button border small link" onClick={open}>
            {btnText}
          </button>
        </Link>
      </td>
    </tr>
  );
};

// Main Component
export class AssignButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      language: '',
      project: '',
      title: ''
    };
  }

  componentDidMount() {
    this.setState({
      language: this.props.course.home_wiki.language || 'www',
      project: this.props.course.home_wiki.project
    });
  }

  getKey() {
    const tag = this.props.role === ASSIGNED_ROLE ? 'assign_' : 'review_';
    if (this.props.student) {
      return tag + this.props.student.id;
    }
    return tag;
  }

  stop(e) {
    return e.stopPropagation();
  }

  handleChangeTitle(e) {
    e.preventDefault();

    const title = e.target.value;
    const articlesTitles = [];
    let language;
    let project;
    title.split('\n').forEach((articleTitle) => {
      if (!articleTitle) {
        articlesTitles.push('');
        return;
      }
      const temp = CourseUtils.articleFromTitleInput(articleTitle);
      articlesTitles.push(temp.title);
      language = temp.language;
      project = temp.project;
    });

    return this.setState({
      title: articlesTitles.join('\n'),
      project: project || this.state.project,
      language: language || this.state.language
    });
  }

  handleWikiChange(val) {
    return this.setState({
      ...val.value
    });
  }

  isAssignmentForTrackedWiki(wikis, assignment) {
    return wikis.some(({ language, project }) => {
      return language === assignment.language && project === assignment.project;
    });
  }

  _onConfirmHandler({ action, assignment, isInTrackedWiki = true, title }) {
    const { student, open } = this.props;
    const studentId = (student && student.id) || null;

    const onConfirm = (e) => {
      open(e);
      this.setState({ title: '' });

      action({
        ...assignment,
        user_id: studentId
      });
    };

    let confirmMessage;
    // Confirm for assigning an article to a student
    if (student) {
      confirmMessage = I18n.t('assignments.confirm_addition', {
        title,
        username: student.username
      });
      // Confirm for adding an unassigned available article
    } else {
      confirmMessage = I18n.t('assignments.confirm_add_available', {
        title
      });
    }

    // If the article is not from a tracked wiki, add a warning message.
    let warningMessage;
    if (!isInTrackedWiki) {
      const wiki = `${assignment.language}.${assignment.project}.org`;
      warningMessage = I18n.t('assignments.warning_untracked_wiki', { wiki });
    }
    return this.props.initiateConfirm({ confirmMessage, onConfirm, warningMessage });
  }

  assign(e) {
    e.preventDefault();
    const { course, role } = this.props;
    this.state.title.split('\n').filter(Boolean).forEach((assignment_title) => {
      const assignment = {
        title: decodeURIComponent(assignment_title).trim(),
        project: this.state.project,
        language: this.state.language,
        course_slug: course.slug,
        role: role
      };

      if (!assignment.title || assignment.title === 'undefined') return;
      if (assignment.title.length > 255) {
        // Title shouldn't exceed 255 chars to prevent mysql errors
        return alert(I18n.t('assignments.title_too_large'));
      }

      const action = this.props.addAssignment;
      const { student } = this.props;
      const studentId = (student && student.id) || null;
      action({
        ...assignment,
          user_id: studentId
      });
    });
  }

  review(e, assignment) {
    e.preventDefault();
    const { course, role } = this.props;

    const reviewing = {
      title: assignment.article_title,
      course_slug: course.slug,
      role
    };

    return this._onConfirmHandler({
      action: this.props.addAssignment,
      assignment: reviewing,
      title: reviewing.title
    });
  }

  update(e, assignment) {
    e.preventDefault();

    return this._onConfirmHandler({
      action: this.props.claimAssignment,
      assignment: {
        id: assignment.id,
        role: this.props.role
      },
      title: assignment.article_title
    });
  }

  unassign(assignment) {
    const confirmMessage = I18n.t('assignments.confirm_deletion');
    const onConfirm = () => {
      this.props.deleteAssignment({ course_slug: this.props.course.slug, ...assignment });
    };
    this.props.initiateConfirm({ confirmMessage, onConfirm });
  }

  render() {
    const {
      assignments, allowMultipleArticles, course, current_user,
      isStudentsPage, is_open, open, permitted, role, student, tooltip_message
    } = this.props;

    let showButton;
    if (!permitted && assignments.length > 1) {
      showButton = (
        <ShowButton
          is_open={is_open}
          open={open}
        />
      );
    }

    let editButton;
    if (!showButton && permitted) {
      let tooltip;
      let tooltipIndicator;
      if (tooltip_message && !is_open) {
        tooltipIndicator = (<span className="tooltip-indicator" />);
        tooltip = (<Tooltip message={tooltip_message} />);
      }

      editButton = (
        <EditButton
          allowMultipleArticles={allowMultipleArticles}
          current_user={current_user}
          is_open={is_open}
          open={open}
          role={role}
          student={student}
          tooltip={tooltip}
          tooltipIndicator={tooltipIndicator}
          assignmentLength={isStudentsPage && assignments.length}
          project={this.state.project}
        />
      );
    }

    const trackedWikis = trackedWikisMaker(this.props.course);

    let editRow;
    if (permitted) {
      let assignmentInput;
      // Add multiple at once via AddAvailableArticles
      if (allowMultipleArticles) {
        assignmentInput = (
          <td>
            <AddAvailableArticles {...this.props} {...this.state} />
            <br />
            <SelectedWikiOption
              language={this.state.language}
              trackedWikis={trackedWikis}
              project={this.state.project}
              handleWikiChange={this.handleWikiChange.bind(this)}
            />
          </td>
        );
        // Add a single assignment
      } else {
        const onSubmit = (e, ...args) => {
          this.assign(e, ...args);
          this.setState({ title: '' });
        };

        assignmentInput = (
          <td>
            <NewAssignmentInput
              language={this.state.language}
              project={this.state.project}
              title={this.state.title}
              assign={onSubmit}
              trackedWikis={trackedWikis}
              handleChangeTitle={this.handleChangeTitle.bind(this)}
              handleWikiChange={this.handleWikiChange.bind(this)}
            />
          </td>
        );
      }

      editRow = (
        <tr className="edit">
          {assignmentInput}
        </tr>
      );
    }

    const wikidataLabels = this.props.wikidataLabels || {};

    const assignmentRows = [];
    // hideAssignedArticles will always be false except in the case
    // of the my_articles.jsx view
    if (!this.props.hideAssignedArticles) {
      assignmentRows.push(
        <AssignedAssignmentRows
          assignments={this.props.assignments}
          key="assigned"
          unassign={this.unassign.bind(this)}
          course={course}
          permitted={permitted}
          role={role}
          wikidataLabels={wikidataLabels}
          project={this.state.project}
        />
      );
    }

    // If you are allowed to edit the assignments generally,
    // either as an instructor or student
    if (permitted) {
      const action = role === REVIEWING_ROLE ? this.review : this.update;
      assignmentRows.push(
        <PotentialAssignmentRows
          assignments={this.props.unassigned}
          assign={action.bind(this)}
          course={course}
          key="potential"
          permitted={permitted}
          role={role}
          wikidataLabels={wikidataLabels}
          project={this.state.project}
        />
      );
    }

    // Add the FindArticles button
    if (role === ASSIGNED_ROLE && !isStudentsPage) {
      const wikiLanguage = this.state.language === null ? 'www' : this.state.language;
      assignmentRows.push(<FindArticles course={course} open={open} project={this.state.project} language={wikiLanguage} key="find-articles-link" />);
    }

    return (
      <div className="pop__container" onClick={this.stop}>
        {showButton}
        {editButton}
        <Popover
          edit_row={editRow}
          is_open={is_open}
          rows={assignmentRows}
        />
      </div>
    );
  }
}

AssignButton.propTypes = {
  allowMultipleArticles: PropTypes.bool,
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  role: PropTypes.number.isRequired,
  is_open: PropTypes.bool,
  open: PropTypes.func.isRequired,
  permitted: PropTypes.bool,
  student: PropTypes.object,
  tooltip_message: PropTypes.string,
  wikidataLabels: PropTypes.object,

  addAssignment: PropTypes.func,
  initiateConfirm: PropTypes.func,
  deleteAssignment: PropTypes.func,
  unassigned: PropTypes.array
};

const mapDispatchToProps = {
  addAssignment,
  deleteAssignment,
  initiateConfirm,
  claimAssignment
};

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(AssignButton)
);
