import React from 'react';
import { connect } from "react-redux";
import TextInput from '../../common/text_input';
import { upgradeAdmin } from '../../../actions/settings_actions';

class AddAdminForm extends React.Component {
  constructor() {
    super();
    this.state = { username: '', confirming: false };
    this.handleUsernameChange = this.handleUsernameChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.renderForm = this.renderForm.bind(this);
    this.renderConfirm = this.renderConfirm.bind(this);
    this.render = this.render.bind(this);
    this.handleConfirm = this.handleConfirm.bind(this);
    this.reset = this.reset.bind(this);
    this.componentWillReceiveProps = this.componentWillReceiveProps.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    // if `this.props.submittingNewAdmin` goes from `true->false` that means the component should reset

    if (this.props.submittingNewAdmin && !nextProps.submittingNewAdmin) {
      this.reset();
    }
  }

  handleUsernameChange(_key, value) {
    return this.setState({ username: value });
  }

  reset() {
    // reset the form: clear the text box, and set confirming to false
    this.setState({ username: '', confirming: false });
  }

  handleConfirm() {
    console.log(this.props);
    this.props.upgradeAdmin(this.state.username);
    this.props.handlePopoverClose();
  }

  handleSubmit(e) {
    e.preventDefault();
    const { username } = this.state;
    this.setState({
      confirming: true,
      confirmMessage: `${I18n.t('settings.admin_users.new.confirm_add_admin')} ${username}?`
    });
   }

  renderForm() {
    return (
      <tr>
        <td>
          <form onSubmit={this.handleSubmit}>
            <TextInput
              id="new_admin_name"
              onChange={this.handleUsernameChange}
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
    );
  }

  renderConfirm() {
    let buttonContent;
    if (this.props.submittingNewAdmin) {
      buttonContent = (<div className="loading__spinner" />);
    } else {
      buttonContent = (
        <button
          className="button border"
          value="confirm"
          onClick={this.handleConfirm}
        >
          {I18n.t('settings.admin_users.new.confirm_add_admin')}
        </button>

      );
    }
    return (
      <tr>
        <td>
          <TextInput
            id="new_admin_name"
            onChange={this.handleUsernameChange}
            value={this.state.username}
            value_key="new_admin_name"
            type="text"
            label={I18n.t('settings.admin_users.new.form_label')}
            placeholder={I18n.t('application.submit')}
          />
          {buttonContent}
        </td>
      </tr>
    );
  }

  render() {
    return this.state.confirming ? this.renderConfirm() : this.renderForm();
  }
}

export default AddAdminForm