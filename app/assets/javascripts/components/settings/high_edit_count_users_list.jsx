import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import List from '../common/list.jsx';
import { addDisallowedUser } from '../../actions/settings_actions';

const HighEditCountUserRow = ({ username, totalRevisions, isDisallowed, onAddToDisallowed }) => {
  return (
    <tr className="user">
      <td className="user__username">
        <p>{username}</p>
      </td>
      <td className="user__real_name">
        <p>{totalRevisions.toLocaleString()}</p>
      </td>
      <td className="user__revoke">
        <p>
          {isDisallowed ? (
            <span className="text-muted">{I18n.t('settings.disallowed_users.already_disallowed')}</span>
          ) : (
            <button
              className="button border small"
              onClick={() => onAddToDisallowed(username)}
            >
              {I18n.t('settings.disallowed_users.add_to_list')}
            </button>
          )}
        </p>
      </td>
    </tr>
  );
};

HighEditCountUserRow.propTypes = {
  username: PropTypes.string.isRequired,
  totalRevisions: PropTypes.number.isRequired,
  isDisallowed: PropTypes.bool.isRequired,
  onAddToDisallowed: PropTypes.func.isRequired,
};

const HighEditCountUsersList = ({ highEditCountUsers }) => {
  const dispatch = useDispatch();
  const disallowedUsers = useSelector(state => state.settings.disallowedUsers);

  const handleAddToDisallowed = (username) => {
    dispatch(addDisallowedUser(username));
  };

  const isAlreadyDisallowed = (username) => {
    return disallowedUsers && disallowedUsers.includes(username);
  };

  const elements = (highEditCountUsers || []).map(user => (
    <HighEditCountUserRow
      key={user.username}
      username={user.username}
      totalRevisions={user.total_revisions}
      isDisallowed={isAlreadyDisallowed(user.username)}
      onAddToDisallowed={handleAddToDisallowed}
    />
  ));

  const keys = {
    username: {
      label: I18n.t('users.username'),
      desktop_only: false,
    },
    total_revisions: {
      label: I18n.t('settings.high_edit_count_users.total_revisions'),
      desktop_only: false
    },
    actions: {
      label: I18n.t('settings.actions'),
      desktop_only: false
    },
  };

  return (
    <div>
      <List
        elements={elements}
        keys={keys}
        table_key="high-edit-count-users"
        none_message={I18n.t('settings.high_edit_count_users.none')}
      />
    </div>
  );
};

HighEditCountUsersList.propTypes = {
  highEditCountUsers: PropTypes.arrayOf(
    PropTypes.shape({
      username: PropTypes.string.isRequired,
      total_revisions: PropTypes.number.isRequired,
    })
  ),
};

export default HighEditCountUsersList;
