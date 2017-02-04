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
    explanation: React.PropTypes.string
  },

  getInitialState() {
    return { userInput: '' };
  },

  onConfirm() {
    this.props.onConfirm(this.state.userInput);
  },

  onCancel() {
    this.props.onCancel();
  },

  onChange(_valueKey, value) {
    this.setState({ userInput: value });
  },

  render() {
    let textInput;
    let description;
    let confirmMessage;
    let lineBreak;
    if (this.props.showInput) {
      textInput = (
        <div>
          <TextInput
            value={this.state.userInput}
            value_key="userInput"
            onChange={this.onChange}
            editable
          />
        </div>
      );
      description = (
        <div className="confirm-explanation">
          {this.props.explanation}
          <br />
          <br />
        </div>
      );
      confirmMessage = (
        <div id = "confirm-message">
          {this.props.message}
        </div>
      );
    }
    else {
      confirmMessage = (
        <p>{this.props.message}</p>
      );
      lineBreak = (
        <br />
      );
    }

    return (
      <Modal modalClass="confirm-modal-overlay">
        <div className="confirm-modal">
          {description}
          {confirmMessage}
          {textInput}
          {lineBreak}
          <div className="pop_container pull-right">
            <button className="button ghost-button" onClick={this.onCancel}>{I18n.t('application.cancel')}</button>
            <button autoFocus className="button dark" onClick={this.onConfirm}>{I18n.t('application.confirm')}</button>
          </div>
        </div>
      </Modal>
    );
  }
});

export default Confirm;
