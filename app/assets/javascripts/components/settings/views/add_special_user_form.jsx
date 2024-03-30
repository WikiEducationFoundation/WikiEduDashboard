import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import CreatableInput from '../../common/creatable_input.jsx';
import { connect } from 'react-redux';
import { upgradeSpecialUser } from '../../../actions/settings_actions';
import TextInput from '../../common/text_input';
import selectStyles from '../../../styles/single_select';

const AddSpecialUserForm = createReactClass({
  propTypes: {
    submittingNewSpecialUser: PropTypes.bool,
    upgradeSpecialUser: PropTypes.func,
    handlePopoverClose: PropTypes.func,
  },

  getInitialState() {
    return { confirming: false, enabled: false, selectedOption: null };
  },

  componentDidUpdate(prevProps) {
    // if `this.props.submittingNewSpecialUser` goes from `true->false` that means the component should reset

    if (prevProps.submittingNewSpecialUser && !this.props.submittingNewSpecialUser) {
      this.reset();
    }
  },

  handleUsernameChange(_key, value) {
    return this.setState({ username: value });
  },

  handlePositionChange(e) {
    const enabled = !!e.value;
    this.setState({ selectedOption: e.value });
    return this.setState({ position: e.value, enabled });
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
    const options = [
      { value: 'communications_manager', label: 'communications_manager' },
      { value: 'classroom_program_manager', label: 'classroom_program_manager' },
      { value: 'outreach_manager', label: 'outreach_manager' },
      { value: 'wikipedia_experts', label: 'wikipedia_experts' },
      { value: 'technical_help_staff', label: 'technical_help_staff' },
      { value: 'survey_alerts_recipient', label: 'survey_alerts_recipient' },
      { value: 'backup_account_creator', label: 'backup_account_creator' },
    ];
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

            <div className="selectPosition"><CreatableInput
              id="specialUserPosition"
              placeholder={'Select the position'}
              onChange={this.handlePositionChange}
              options={options}
              styles={selectStyles}
            />
            </div>
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
        <button
          onClick={this.handleConfirm}
          className="button border"
          value="confirm"
        >
          {I18n.t('settings.special_users.new.confirm_add_special_user')}
        </button>
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
