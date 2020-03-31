import React from 'react';
import PropTypes from 'prop-types';

// Components
import AssignCell from '@components/common/AssignCell/AssignCell.jsx';

// Helper Functions
import { groupByAssignmentType } from '@components/util/helpers';

// Constants
import {
  ASSIGNED_ROLE, REVIEWING_ROLE
} from '~/app/assets/javascripts/constants/assignments';

export const Header = ({
  assignments, course, current_user, selected, wikidataLabels
}) => {
  const {
    assigned, reviewing,
    unassigned, reviewable
  } = groupByAssignmentType(assignments, selected.id);

  return (
    <aside className="header">
      <section>
        <h3>{ selected.username }</h3>
        <div className="sandbox-link">
          <a href={selected.sandbox_url} target="_blank">{I18n.t('users.sandboxes')}</a>
            &nbsp;
          <a href={selected.contribution_url} target="_blank">{I18n.t('users.edits')}</a>
        </div>
      </section>
      <div className="button-actions">
        <AssignCell
          assignments={assigned}
          editable
          course={course}
          current_user={current_user}
          id="user_assigned"
          prefix={I18n.t('users.my_assigned')}
          role={ASSIGNED_ROLE}
          student={selected}
          tooltip_message={I18n.t('assignments.assign_tooltip')}
          unassigned={unassigned}
          wikidataLabels={wikidataLabels}
        />
        <AssignCell
          assignments={reviewing}
          course={course}
          current_user={current_user}
          editable
          id="user_reviewing"
          prefix={I18n.t('users.my_reviewing')}
          role={REVIEWING_ROLE}
          student={selected}
          tooltip_message={I18n.t('assignments.review_tooltip')}
          unassigned={reviewable}
          wikidataLabels={wikidataLabels}
        />
      </div>
    </aside>
  );
};

Header.propTypes = {
  selected: PropTypes.shape({
    username: PropTypes.string.isRequired
  }).isRequired,
  wikidataLabels: PropTypes.object
};

export default Header;
