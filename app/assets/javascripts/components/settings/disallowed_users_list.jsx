import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import List from '../common/list.jsx';
import { removeDisallowedUser } from '../../actions/settings_actions';

const DisallowedUserRow = ({ username, onRemove }) => {
    const handleRemove = () => {
        onRemove(username);
    };

    return (
      <tr className="user">
        <td className="user__username">
          <p>{username}</p>
        </td>
        <td className="user__revoke">
          <p>
            <button
              className="button danger"
              onClick={handleRemove}
            >
              {I18n.t('settings.disallowed_users.remove_button')}
            </button>
          </p>
        </td>
      </tr>
    );
};

DisallowedUserRow.propTypes = {
    username: PropTypes.string.isRequired,
    onRemove: PropTypes.func.isRequired,
};

const DisallowedUsersList = ({ disallowedUsers }) => {
    const dispatch = useDispatch();

    const handleRemove = (username) => {
        dispatch(removeDisallowedUser(username));
    };

    const elements = (disallowedUsers || []).map(username => (
      <DisallowedUserRow
        key={username}
        username={username}
        onRemove={handleRemove}
      />
    ));

    const keys = {
        username: {
            label: I18n.t('users.username'),
            desktop_only: false,
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
          table_key="disallowed-users"
          none_message={I18n.t('settings.disallowed_users.none')}
        />
      </div>
    );
};

DisallowedUsersList.propTypes = {
    disallowedUsers: PropTypes.arrayOf(PropTypes.string),
};

export default DisallowedUsersList;
