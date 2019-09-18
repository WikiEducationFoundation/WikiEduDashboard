import React from 'react';

// components
import Actions from './Actions';
import Links from './Links';

const isEnglishWikipedia = ({ assignment, course }) => () => {
  if (course.home_wiki.language === 'en' && course.home_wiki.project === 'wikipedia') {
    if (typeof assignment.language === 'undefined') {
      return true;
    }
  }
  if (assignment.language === 'en' && assignment.project === 'wikipedia') {
    return true;
  }

  return false;
};

const unassign = ({ assignment, course, initiateConfirm, deleteAssignment }) => {
  const body = { course_slug: course.slug, ...assignment };
  const message = I18n.t('assignments.confirm_deletion');

  return () => initiateConfirm(message, () => deleteAssignment(body));
};

export default ({
  article, articleTitle, assignment, course, current_user, isComplete, username,
  deleteAssignment, fetchAssignments, initiateConfirm, updateAssignmentStatus
}) => (
  <header aria-label={`${articleTitle} assignment`} className="header-wrapper">
    <Links
      articleTitle={articleTitle}
      assignment={assignment}
      current_user={current_user}
    />
    <Actions
      article={article}
      assignment={assignment}
      courseSlug={course.slug}
      current_user={current_user}
      isEnglishWikipedia={isEnglishWikipedia({ assignment, course })}
      isComplete={isComplete}
      refreshAssignments={fetchAssignments}
      unassign={unassign({ assignment, course, initiateConfirm, deleteAssignment })}
      handleUpdateAssignment={updateAssignmentStatus}
      username={username}
    />
  </header>
)
;
