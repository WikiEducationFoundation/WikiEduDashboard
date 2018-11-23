import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { upgradeSpecialUser } from '../../../actions/settings_actions';
import TextInput from '../../common/text_input';

const AddSpecialUserForm = createReactClass({
  propTypes: {
    submittingNewSpecialUser: PropTypes.bool,
    upgradeSpecialUser: PropTypes.func,
    handlePopoverClose: PropTypes.func,
  },

  getInitialState() {
    return { confirming: false, enabled: false };
  },

  componentWillReceiveProps(nextProps) {
    // if `this.props.submittingNewSpecialUser` goes from `true->false` that means the component should reset

    if (this.props.submittingNewSpecialUser && !nextProps.submittingNewSpecialUser) {
      this.reset();
    }
  },

  handleUsernameChange(_key, value) {
    return this.setState({ username: value });
  },

  handlePositionChange(e) {
    const enabled = !!e.target.value;
    return this.setState({ position: e.target.value, enabled });
  },

  reset() {
    // reset the form: clear the text box, and set confirming to false
    this.setState({ username: '', confirming: false });
  },

  handleConfirm(e) {
    this.props.upgradeSpecialUser(this.state.username, this.state.position);
    this.props.handlePopoverClose(e);
  },

  handleSubmit(e) {
    e.preventDefault();
    const { username } = this.state;
    this.setState({
      confirming: true,
      confirmMessage: `${I18n.t('settings.special_users.new.confirm_add_special_user')} ${username}?`
    });
   },

  renderForm() {
    const buttonClass = this.state.enabled ? 'button border' : 'button border disabled';
    return (
      <tr>
        <td>
          <form onSubmit={this.handleSubmit}>
            <TextInput
              id="new_special_user"
              onChange={this.handleUsernameChange}
              value={this.state.username}
              value_key="new_special_user"
              editable
              required
              type="text"
              label={I18n.t('settings.special_users.new.form_label')}
              placeholder={I18n.t('settings.special_users.new.form_placeholder')}
            />
            <select onChange={this.handlePositionChange}>
              <option value="">Select the position</option>
              <option>communications_manager</option>
              <option>classroom_program_manager</option>
              <option>outreach_manager</option>
              <option>technical_help_staff</option>
              <option>survey_alerts_recipient</option>
            </select>
            <button className={buttonClass} type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    );
  },

  renderConfirm() {
    let buttonContent;
    if (this.props.submittingNewSpecialUser) {
      buttonContent = (<div className="loading__spinner" />);
    } else {
      buttonContent = (
        <form onSubmit={this.handleConfirm}>
          <button
            className="button border"
            value="confirm"
          >
            {I18n.t('settings.special_users.new.confirm_add_special_user')}
          </button>
        </form>


      );
    }
    return (
      <tr>
        <td>
          <TextInput
            id="confirm_special_user"
            onChange={this.handleUsernameChange}
            value={this.state.username}
            value_key="confirm_special_user"
            type="text"
            label={I18n.t('settings.special_users.new.form_label')}
            placeholder={I18n.t('application.submit')}
          />
          {buttonContent}
        </td>
      </tr>
    );
  },

  render() {
    return this.state.confirming ? this.renderConfirm() : this.renderForm();
  },
});

const mapStateToProps = state => ({
  submittingNewSpecialUser: state.settings.submittingNewSpecialUser,
});

const mapDispatchToProps = {
  upgradeSpecialUser
};

export default connect(mapStateToProps, mapDispatchToProps)(AddSpecialUserForm);
