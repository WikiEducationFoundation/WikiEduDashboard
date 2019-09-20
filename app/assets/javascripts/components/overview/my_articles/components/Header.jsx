import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

// components
import AssignCell from '../../../students/assign_cell.jsx';

// constants
import {
  ASSIGNED_ROLE, REVIEWING_ROLE
} from '../../../../constants/assignments';

export const Header = ({
  assigned, course, current_user, reviewable, reviewing, unassigned, wikidataLabels
}) => (
  <div className="section-header my-articles-header">
    <h3>{I18n.t('courses.my_articles')}</h3>
    <div className="controls">
      <AssignCell
        assignments={assigned}
        editable
        course={course}
        current_user={current_user}
        hideAssignedArticles
        id="user_assigned"
        prefix={I18n.t('users.my_assigned')}
        role={ASSIGNED_ROLE}
        student={current_user}
        tooltip_message={I18n.t('assignments.assign_tooltip')}
        unassigned={unassigned}
        wikidataLabels={wikidataLabels}
      />
      <AssignCell
        assignments={reviewing}
        course={course}
        current_user={current_user}
        editable
        hideAssignedArticles
        id="user_reviewing"
        prefix={I18n.t('users.my_reviewing')}
        role={REVIEWING_ROLE}
        student={current_user}
        tooltip_message={I18n.t('assignments.review_tooltip')}
        unassigned={reviewable}
        wikidataLabels={wikidataLabels}
      />
      <Link to={`/courses/${course.slug}/article_finder`}>
        <button className="button border small assign-button link">Find Articles</button>
      </Link>
    </div>
  </div>
);

Header.propTypes = {
  // props
  assigned: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  reviewable: PropTypes.array.isRequired,
  reviewing: PropTypes.array.isRequired,
  unassigned: PropTypes.array.isRequired,
  wikidataLabels: PropTypes.object.isRequired,
};

export default Header;
