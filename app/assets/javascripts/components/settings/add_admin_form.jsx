import React from 'react';
import { connect } from "react-redux";
import TextInput from '../common/text_input';
import updateAdminStatus from '../../actions/settings_actions';
import { initiateConfirm } from '../../actions/confirm_actions';

class AddAdminForm extends React.Component {

  constructor() {
    super();
    this.state = {username: ''};
    this.handleNameChange = this.handleNameChange.bind(this);
    this.addAdmin = this.addAdmin.bind(this);
    this.render = this.render.bind(this);
  }

  handleNameChange(_key, value) {
    return this.setState({ username: value });
  }

  addAdmin(e) {
    e.preventDefault();
    const { username } = this.state;
    const onConfirm = () => {
      updateAdminStatus(username, true)
    };

    const confirmMessage = `${I18n.t('settings.admin_users.new.confirm_add_admin')} for ${username}`;
    return this.props.initiateConfirm(confirmMessage, onConfirm)

   }

   render() {
    return (
      <tr>
        <td>
          <form onSubmit={this.addAdmin}>
            <TextInput
              id="new_admin_name"
              onChange={this.handleNameChange}
              value={this.state.username}
              value_key="new_admin_name"
              editable
              required
              type="text"
              label={I18n.t('settings.admin_users.new.form_label')}
              placeholder={I18n.t('settings.admin_users.new.form_placeholder')}
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    )
   }
}
const mapDispatchToProps = { initiateConfirm };

export default connect(null, mapDispatchToProps)(AddAdminForm)
