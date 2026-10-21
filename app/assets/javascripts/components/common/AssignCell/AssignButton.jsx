import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
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
import { verifyMainSpaceArticle } from '@actions/article_actions.js';
import { addNotification } from '@actions/notification_actions.js';
import { safeDecodeURIComponent } from '../../../utils/strings';

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
        {text}
      </button>
    </span>
  );
};

const RemoveAssignmentButton = ({ assignment, unassign }) => {
  return (
    <span>
      <button
        aria-label={I18n.t('assignments.remove')}
        className="button border assign-selection-button"
        onClick={() => unassign(assignment)}
      >
        {I18n.t('assignments.remove')}
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

// A new article being reviewed exists only as the author's sandbox draft,
// so peer review rows link there instead of to the missing mainspace page.
const isReviewOfDraft = (assignment, role) => {
  return role === REVIEWING_ROLE && !assignment.article_id && Boolean(assignment.sandbox_url);
};

const reviewRowUrl = (assignment, article, role) => {
  return isReviewOfDraft(assignment, role) ? assignment.sandbox_url : article.url;
};

// A review the student already has links to the draft of the classmate whose
// article it is. If no classmate is drafting it, it links to the article.
const assignedReviewUrl = (review, article, role, courseAssignments) => {
  const draft = role === REVIEWING_ROLE && CourseUtils.draftForReview(review, courseAssignments);
  return draft ? draft.sandbox_url : article.url;
};

const AssignedAssignmentRows = ({
  assignments = [], courseAssignments = [], course, permitted, role, wikidataLabels, project, unassign // functions
}) => {
  const elements = assignments.map((assignment) => {
    const article = getArticle(assignment, course, wikidataLabels);

    return (
      <tr key={assignment.id} className="assignment">
        <td>
          <ArticleLink articleUrl={assignedReviewUrl(assignment, article, role, courseAssignments)} title={article.title} />
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
          <ArticleLink articleUrl={reviewRowUrl(assignment, article, role)} title={article.title} />
          {
            isReviewOfDraft(assignment, role) && assignment.username
            && <small className="review-draft-owner">{I18n.t('assignments.review_classmate_draft', { username: assignment.username })}</small>
          }
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
  allowMultipleArticles, current_user, is_open, setHover, open, role, student,
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
    <div className="tooltip-trigger" onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
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
  const courseAssignments = useSelector(state => state.assignments.assignments);
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

    let articleLanguage;
    let articleProject;

    // loop for each individual article to detect project/language from URLs/prefixes
    text.split('\n').forEach((articleTitle) => {
      if (!articleTitle) return;

      const article = CourseUtils.articleFromTitleInput(articleTitle);
      articleLanguage = article.language || articleLanguage;
      articleProject = article.project || articleProject;
    });

    setTitle(text);
    setProject(articleProject || course.home_wiki.project);
    setLanguage(articleLanguage || (course.home_wiki.language || 'www'));
  };

  const handleWikiChange = (chosenWiki) => {
    setLanguage(chosenWiki.value.language);
    setProject(chosenWiki.value.project);
  };

  const _onConfirmHandler = ({ action, assignment, isInTrackedWiki = true, title: confirmedTitle }) => {
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
    if (student) {
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


  // Mainspace validation applies to Wikipedia articles in ClassroomProgramCourse only.
  // Other projects (Commons, Wiktionary, etc.) have different namespace conventions.
  const requiresMainspace = (assignment) => {
    if (course.type !== 'ClassroomProgramCourse') return false;
    return !assignment.project || assignment.project === 'wikipedia';
  };

  // Validates if Course type is ClassroomProgramCourse and verify articles using verifyMainSpaceArticle
  const validateMainspaceArticles = async (assignment) => {
    if (!requiresMainspace(assignment)) {
      return { valid: true };
    }

    const result = await dispatch(
      verifyMainSpaceArticle(assignment.title, assignment.language, assignment.project)
    );

    if (!result?.valid) {
      return {
        valid: false,
        error: result?.message || I18n.t('assignments.invalid_mainspace_article'),
      };
    }

    return { valid: true };
  };


  const assign = async (e) => {
    e.preventDefault();
    const articles = title.split('\n').filter(Boolean);
    if (articles.length === 0) return;

    const notifications = [];

    await Promise.all(
      articles.map(async (assignment_title) => {
        // Parse the input — could be a URL or a plain title
        const parsed = CourseUtils.articleFromTitleInput(assignment_title);
        const assignment = {
          title: parsed.title || safeDecodeURIComponent(assignment_title).trim(),
          project: parsed.project || project,
          language: parsed.language || language,
          course_slug: course.slug,
          role
        };

        if (!assignment.title || assignment.title === 'undefined') return;
        if (assignment.title.length > 255) {
          notifications.push({
            message: I18n.t('assignments.title_too_large'),
            type: 'error',
            closable: true,
          });
          return;
        }

        const studentId = student?.id ?? null;

        if (role === REVIEWING_ROLE) {
          // A classmate's sandbox URL or title stands for their assigned
          // article, which is what a peer review is assigned to.
          const draftAssignment = CourseUtils.assignmentForSandbox(parsed, courseAssignments, studentId);
          if (draftAssignment) {
            dispatch(addAssignment({
              ...assignment,
              title: draftAssignment.article_title,
              language: draftAssignment.language || assignment.language,
              project: draftAssignment.project || assignment.project,
              user_id: studentId
            }));
            return;
          }
          if (requiresMainspace(assignment) && /^user:/i.test(assignment.title)) {
            notifications.push({
              message: I18n.t('assignments.review_sandbox_not_found', { title: assignment.title }),
              type: 'error',
              closable: true,
            });
            return;
          }
        }

        const validation = await validateMainspaceArticles(assignment);

        if (!validation.valid) {
          notifications.push({
            message: validation.error,
            type: 'error',
            closable: true,
          });
          return;
        }

        dispatch(addAssignment({
          ...assignment,
          user_id: studentId
        }));
      })
    );

    // Show all errors immediately after all validations
    if (notifications.length > 0) {
      notifications.forEach(n => dispatch(addNotification(n)));
    }

    // Clear input only if no errors
    if (notifications.length === 0) {
      setTitle('');
    }
  };

  const assignAvailableArticles = async (assignment) => {
    const validation = await validateMainspaceArticles(assignment);

    if (validation.valid) {
      dispatch(addAssignment(assignment));
    } else {
      // Show error right away for single assignment
      dispatch(addNotification({
        message: validation.error,
        type: 'error',
        closable: true,
      }));
    }
  };

  const review = (e, assignment) => {
    e.preventDefault();

    const reviewing = {
      title: assignment.article_title,
      course_slug: course.slug,
      language: assignment.language,
      project: assignment.project,
      role
    };

    return _onConfirmHandler({
      action: addAssignment,
      assignment: reviewing,
      title: reviewing.title
    });
  };

  const update = (e, assignment) => {
    e.preventDefault();

    return _onConfirmHandler({
      action: claimAssignment,
      assignment: {
        id: assignment.id,
        role
      },
      title: assignment.article_title
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

  const [hover, setHover] = useState();
  let editButton;
  if (!showButton && permitted) {
    let tooltip;
    let tooltipIndicator;
    if (tooltip_message && !isOpen) {
      tooltipIndicator = (<span className={`${hover ? 'tooltip-indicator-hover' : 'tooltip-indicator'}`} />);
      tooltip = (<Tooltip message={tooltip_message} />);
    }

    editButton = (
      <EditButton
        allowMultipleArticles={allowMultipleArticles}
        current_user={current_user}
        is_open={isOpen}
        open={open}
        setHover={setHover}
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
            course_id={course_id} addAssignment={assignment => assignAvailableArticles(assignment)} open={open}
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
        courseAssignments={courseAssignments}
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
    // onClick={stop} only calls e.stopPropagation() to keep "click outside"
    // hooks from firing on clicks within the popover; no real interaction.
    // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions
    <div className="pop__container assignment-popover" onClick={stop} ref={ref}>
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
