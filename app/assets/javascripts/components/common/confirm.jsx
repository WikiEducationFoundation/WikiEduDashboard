import React from 'react';
import Modal from './modal.jsx';
import TextInput from './text_input.jsx';

const Confirm = React.createClass({
  displayName: 'Confirm',

  propTypes: {
    onConfirm: React.PropTypes.func.isRequired,
    onCancel: React.PropTypes.func.isRequired,
    message: React.PropTypes.string.isRequired,
    showInput: React.PropTypes.bool,
    prompt: React.PropTypes.string
  },

  getInitialState() {
    return { prompt: '' };
  },

  onConfirm() {
    this.props.onConfirm(this.props.prompt);
  },

  onCancel() {
    this.props.onCancel();
  },

  onChange(_valueKey, value) {
    this.setState({ prompt: value });
  },

  render() {
    let textInput;
    let joinDetails;
    if (this.props.showInput) {
      textInput = (
        <div className="input">
          <TextInput
            value={this.state.prompt}
            value_key="prompt"
            onChange={this.onChange}
            editable
          />
        </div>
      );
      joinDetails = (
        <div className="details">
          <h5>More details on how to get the password</h5>
          <p>nb hbhbfhbfhbfhbfh jdvjdjvbfvjfbvfbvfbf dnd<br />
          jvjdvbjbvjfbvjfvbjfb ddvndjvndjvndjvndjvdkvmdkv
          </p>
        </div>
      );
    }
    return (
      <Modal modalClass="confirm-modal-overlay">
        <div className="confirm-modal">
          <h5>{this.props.message}</h5>
          {textInput}
          <br />
          <div className="pop_container pull-right">
            <button className="button ghost-button" onClick={this.onCancel}>{I18n.t('application.cancel')}</button>
            <button autoFocus className="button dark" onClick={this.onConfirm}>{I18n.t('application.confirm')}</button>
          </div>
          {joinDetails}
        </div>
      </Modal>
    );
  }
});

export default Confirm;

