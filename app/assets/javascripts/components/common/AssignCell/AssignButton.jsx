import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { Link } from 'react-router-dom';

import Popover from '../popover.jsx';
import { initiateConfirm } from '../../../actions/confirm_actions';
import { addAssignment, deleteAssignment, claimAssignment } from '../../../actions/assignment_actions';
import useExpandablePopover from '../../../hooks/useExpandablePopover';
import CourseUtils from '../../../utils/course_utils.js';
import AddAvailableArticles from '../../articles/add_available_articles';
import NewAssignmentInput from '../../assignments/new_assignment_input';
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '~/app/assets/javascripts/constants';
import SelectedWikiOption from '../selected_wiki_option';
import { trackedWikisMaker } from '../../../utils/wiki_utils';
import ArticleUtils from '../../../utils/article_utils';
import API from '../../../utils/api';
import logErrorMessage from '../../../utils/log_error_message.js';

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

  const handleClick = async (e) => {
    try {
      const categoryMember = await API.checkArticleInWikiCategory([assignment.article_title]);
      assign(e, assignment, categoryMember[0]);
    } catch (error) {
      logErrorMessage(error);
    }
  };

  return (
    <span>
      <button
        aria-label="Add"
        className="button border assign-selection-button"
        onClick={e => handleClick(e)}
      >
        {text}
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
  if (!articleUrl) return (<span>{title}</span>);
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
        <h3>{text}</h3>
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
        <h3>{text}</h3>
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
const AssignButton = ({ course, role, course_id, wikidataLabels = {}, hideAssignedArticles,
  assignments, unassigned, student, allowMultipleArticles, current_user, isStudentsPage,
  permitted, tooltip_message }) => {
  const dispatch = useDispatch();
  const [language, setLanguage] = useState('');
  const [project, setProject] = useState('');
  const [title, setTitle] = useState('');

  useEffect(() => {
    setLanguage(course.home_wiki.language || 'www');
    setProject(course.home_wiki.project);
  }, []);

  const getKey = () => {
    const tag = role === ASSIGNED_ROLE ? 'assign_' : 'review_';
    return student ? tag + student.id : tag;
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const stop = (e) => {
    return e.stopPropagation();
  };

  const handleChangeTitle = (e) => {
    e.preventDefault();

    // this text contains the titles/links of the article separated by new lines
    const text = e.target.value;
    const articlesTitles = [];

    let articleLanguage;
    let articleProject;

    // loop for each individual article
    text.split('\n').forEach((articleTitle) => {
      // if the article title is empty, then skip it
      if (!articleTitle) {
        // add an empty string to the array so that new lines are preserved
        articlesTitles.push('');
        return;
      }

      const article = CourseUtils.articleFromTitleInput(articleTitle);
      articlesTitles.push(article.title);
      articleLanguage = article.language;
      articleProject = article.project;
    });

    setTitle(articlesTitles.join('\n'));
    setProject(articleProject || project);
    setLanguage(articleLanguage || language);
  };

  const handleWikiChange = (chosenWiki) => {
    setLanguage(chosenWiki.value.language);
    setProject(chosenWiki.value.project);
  };

  const _onConfirmHandler = ({ action, assignment, isInTrackedWiki = true, title: confirmedTitle, categoryMember }) => {
    const studentId = (student && student.id) || null;
    const onConfirm = (e) => {
      open(e);
      setTitle('');

      dispatch(action({
        ...assignment,
        user_id: studentId
      }));
    };

    let confirmMessage;
    // Confirm for assigning an article to a student
    if (categoryMember) {
      confirmMessage = I18n.t('articles.discouraged_article', {
        type: 'Assigning',
        action: 'assign',
        article: 'article',
        article_list: categoryMember,
      });
    } else if (student) {
      confirmMessage = I18n.t('assignments.confirm_addition', {
        title: confirmedTitle,
        username: student.username
      });
      // Confirm for adding an unassigned available article
    } else {
      confirmMessage = I18n.t('assignments.confirm_add_available', {
        title: confirmedTitle
      });
    }

    // If the article is not from a tracked wiki, add a warning message.
    let warningMessage;
    if (!isInTrackedWiki) {
      const wiki = `${assignment.language}.${assignment.project}.org`;
      warningMessage = I18n.t('assignments.warning_untracked_wiki', { wiki });
    }
    return dispatch(initiateConfirm({ confirmMessage, onConfirm, warningMessage }));
  };

  const assign = async (e) => {
    e.preventDefault();

    const assignArticle = () => {
      title.split('\n').filter(Boolean).forEach((assignment_title) => {
        const assignment = {
          title: decodeURIComponent(assignment_title).trim(),
          project: project,
          language: language,
          course_slug: course.slug,
          role: role
        };

        if (!assignment.title || assignment.title === 'undefined') return;
        if (assignment.title.length > 255) {
          // Title shouldn't exceed 255 chars to prevent mysql errors
          return alert(I18n.t('assignments.title_too_large'));
        }

        const studentId = (student && student.id) || null;
        dispatch(addAssignment({
          ...assignment,
          user_id: studentId
        }));
      });
    };

    const articleTitles = title.split('\n').map(item => item.trim()).filter(Boolean);
    const categoryMember = await API.checkArticleInWikiCategory(articleTitles);

    if (categoryMember.length > 0) {
      const confirmMessage = I18n.t('articles.discouraged_article', {
        type: 'Assigning',
        action: 'assign',
        article: categoryMember.length > 1 ? 'articles' : 'article',
        article_list: categoryMember.join(', '),
      });

      dispatch(initiateConfirm({ confirmMessage, onConfirm: assignArticle }));
    } else {
      assignArticle();
    }
  };

  const review = (e, assignment) => {
    e.preventDefault();

    const reviewing = {
      title: assignment.article_title,
      course_slug: course.slug,
      role
    };

    return _onConfirmHandler({
      action: addAssignment,
      assignment: reviewing,
      title: reviewing.title
    });
  };

  const update = (e, assignment, categoryMember) => {
    e.preventDefault();

    return _onConfirmHandler({
      action: claimAssignment,
      assignment: {
        id: assignment.id,
        role: role
      },
      title: assignment.article_title,
      categoryMember: categoryMember
    });
  };

  const unassign = (assignment) => {
    const confirmMessage = I18n.t('assignments.confirm_deletion');
    const onConfirm = () => {
      dispatch(deleteAssignment({ course_slug: course.slug, ...assignment }));
    };
    dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  };

  let showButton;
  if (!permitted && assignments.length > 1) {
    showButton = (
      <ShowButton
        is_open={isOpen}
        open={open}
      />
    );
  }

  let editButton;
  if (!showButton && permitted) {
    let tooltip;
    let tooltipIndicator;
    if (tooltip_message && !isOpen) {
      tooltipIndicator = (<span className="tooltip-indicator" />);
      tooltip = (<Tooltip message={tooltip_message} />);
    }

    editButton = (
      <EditButton
        allowMultipleArticles={allowMultipleArticles}
        current_user={current_user}
        is_open={isOpen}
        open={open}
        role={role}
        student={student}
        tooltip={tooltip}
        tooltipIndicator={tooltipIndicator}
        assignmentLength={isStudentsPage && assignments.length}
        project={project}
      />
    );
  }

  const trackedWikis = trackedWikisMaker(course);

  let editRow;
  if (permitted) {
    let assignmentInput;
    // Add multiple at once via AddAvailableArticles
    if (allowMultipleArticles) {
      assignmentInput = (
        <td>
          <AddAvailableArticles
            language={language} project={project} title={title} role={role}
            course_id={course_id} addAssignment={assignment => dispatch(addAssignment(assignment))} open={open}
          />
          <br />
          <SelectedWikiOption
            language={language}
            trackedWikis={trackedWikis}
            project={project}
            handleWikiChange={handleWikiChange}
          />
        </td>
      );
      // Add a single assignment
    } else {
      const onSubmit = (e, ...args) => {
        assign(e, ...args);
        setTitle('');
      };

      assignmentInput = (
        <td>
          <NewAssignmentInput
            language={language}
            project={project}
            title={title}
            assign={onSubmit}
            trackedWikis={trackedWikis}
            handleChangeTitle={handleChangeTitle}
            handleWikiChange={handleWikiChange}
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

  const assignmentRows = [];
  // hideAssignedArticles will always be false except in the case
  // of the my_articles.jsx view
  if (!hideAssignedArticles) {
    assignmentRows.push(
      <AssignedAssignmentRows
        assignments={assignments}
        key="assigned"
        unassign={unassign}
        course={course}
        permitted={permitted}
        role={role}
        wikidataLabels={wikidataLabels}
        project={project}
      />
    );
  }

  // If you are allowed to edit the assignments generally,
  // either as an instructor or student
  if (permitted) {
    const action = role === REVIEWING_ROLE ? review : update;
    assignmentRows.push(
      <PotentialAssignmentRows
        assignments={unassigned}
        assign={action}
        course={course}
        key="potential"
        permitted={permitted}
        role={role}
        wikidataLabels={wikidataLabels}
        project={project}
      />
    );
  }

  // Add the FindArticles button
  if (role === ASSIGNED_ROLE && !isStudentsPage) {
    const wikiLanguage = language === null ? 'www' : language;
    assignmentRows.push(<FindArticles course={course} open={open} project={project} language={wikiLanguage} key="find-articles-link" />);
  }

  return (
    <div className="pop__container" onClick={stop} ref={ref}>
      {showButton}
      {editButton}
      <Popover
        edit_row={editRow}
        is_open={isOpen}
        rows={assignmentRows}
      />
    </div>
  );
};

AssignButton.propTypes = {
  allowMultipleArticles: PropTypes.bool,
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  role: PropTypes.number.isRequired,
  is_open: PropTypes.bool,
  permitted: PropTypes.bool,
  student: PropTypes.object,
  tooltip_message: PropTypes.string,
  wikidataLabels: PropTypes.object,
  unassigned: PropTypes.array
};

export default (AssignButton);
