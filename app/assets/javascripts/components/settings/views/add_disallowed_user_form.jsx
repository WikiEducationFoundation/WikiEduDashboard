import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { addDisallowedUser } from '../../../actions/settings_actions';
import TextInput from '../../common/text_input';

const AddDisallowedUserForm = ({ handlePopoverClose }) => {
    const [username, setUsername] = useState('');
    const dispatch = useDispatch();
    const submitting = useSelector(state => state.settings.submittingDisallowedUser);

    const handleUsernameChange = (_key, value) => {
        setUsername(value);
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        if (username.trim()) {
            dispatch(addDisallowedUser(username.trim()));
            setUsername('');
            handlePopoverClose(e);
        }
    };

    return (
      <tr>
        <td>
          <form onSubmit={handleSubmit}>
            <TextInput
              id="new_disallowed_user"
              onChange={handleUsernameChange}
              value={username}
              value_key="new_disallowed_user"
              editable
              required
              type="text"
              label={I18n.t('settings.disallowed_users.add_button')}
              placeholder={I18n.t('users.username_placeholder')}
            />
            <button
              className="button border"
              type="submit"
              disabled={submitting || !username.trim()}
            >
              {submitting ? I18n.t('application.loading') : I18n.t('settings.disallowed_users.submit_button')}
            </button>
          </form>
        </td>
      </tr>
    );
};

AddDisallowedUserForm.propTypes = {
    handlePopoverClose: PropTypes.func.isRequired,
};

export default AddDisallowedUserForm;
