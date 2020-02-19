import React from 'react';
import PropTypes from 'prop-types';
import AssignButton from './AssignButton.jsx';
import { trunc } from '../../../utils/strings';
import CourseUtils from '../../../utils/course_utils.js';

// Helper Components
const ArticleLink = ({ content, href, prefix }) => {
  if (href) {
    content = (
      <a
        href={href}
        onClick={e => e.stopPropagation()}
        target="_blank"
      >
        { content }
      </a>
    );
  }

  return (
    <span>
      { prefix }{ content }
    </span>
  );
};

// Main Component
export const AssignCell = (props) => {
  const {
    assignments, course, current_user,
    editable, isStudentsPage, prefix, student
  } = props;

  let link;
  if (isStudentsPage && assignments.length) {
    const article = CourseUtils.articleFromAssignment(assignments[0], course.home_wiki);
    if (assignments.length > 1) {
      const count = I18n.t('users.number_of_articles', { count: assignments.length });
      link = <ArticleLink prefix={prefix} content={count} />;
    } else {
      const title = trunc(article.formatted_title, 30);
      link = <ArticleLink prefix={prefix} href={article.url} content={title} />;
    }
  } else if (!current_user) {
    link = <ArticleLink content={I18n.t('users.no_articles')} />;
  }

  let isCurrentUser;
  if (student) { isCurrentUser = current_user.id === student.id; }
  const instructorOrAdmin = current_user.isInstructor || current_user.admin;
  const permitted = (isCurrentUser || instructorOrAdmin) && editable;

  return (
    <div className="inline-button-peer">
      {link}
      <AssignButton {...props} permitted={permitted} />
    </div>
  );
};

AssignCell.propTypes = {
  assignments: PropTypes.array,
  prefix: PropTypes.string,
  current_user: PropTypes.object,
  student: PropTypes.object,
  editable: PropTypes.bool,
  role: PropTypes.number,
  tooltip_message: PropTypes.string,
  course: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object
};

export default AssignCell;
