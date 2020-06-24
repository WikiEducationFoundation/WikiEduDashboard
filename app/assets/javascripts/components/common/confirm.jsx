import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import Modal from './modal.jsx';
import TextInput from './text_input.jsx';
import { confirmAction, cancelAction } from '../../actions';

const Confirm = createReactClass({
  displayName: 'Confirm',

  propTypes: {
    onConfirm: PropTypes.func,
    onCancel: PropTypes.func,
    showInput: PropTypes.bool,
    explanation: PropTypes.string,
    confirmAction: PropTypes.func.isRequired,
    cancelAction: PropTypes.func.isRequired
  },

  getInitialState() {
    return { userInput: '' };
  },

  onConfirm() {
    this.props.onConfirm(this.state.userInput);
    this.props.confirmAction();
  },

  onCancel() {
    if (this.props.onCancel) {
      this.props.onCancel();
    }
    this.props.cancelAction();
  },

  onChange(_valueKey, value) {
    this.setState({ userInput: value });
  },

  render() {
    if (!this.props.confirmationActive) { return <div />; }
    let textInput;
    let description;
    let confirmMessage;
    let lineBreak;
    let warningMessage;
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
      confirmMessage = (
        <div id="confirm-message">
          {this.props.confirmMessage}
        </div>
      );
    } else {
      confirmMessage = (
        <p>{this.props.confirmMessage}</p>
      );
      lineBreak = (
        <br />
      );
    }

    if (this.props.explanation) {
      description = (
        <div className="confirm-explanation">
          {this.props.explanation}
          <br />
          <br />
        </div>
      );
    }

    if (this.props.warningMessage) {
      warningMessage = (
        <div className="warning slim">
          <p dangerouslySetInnerHTML={{ __html: this.props.warningMessage }} />
        </div>
      );
    }

    return (
      <Modal modalClass="confirm-modal-overlay">
        <div className="confirm-modal" role="alert">
          {description}
          {confirmMessage}
          {textInput}
          {warningMessage}
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

const mapStateToProps = state => ({
  confirmationActive: state.confirm.confirmationActive,
  confirmMessage: state.confirm.confirmMessage,
  explanation: state.confirm.explanation,
  onConfirm: state.confirm.onConfirm,
  showInput: state.confirm.showInput,
  warningMessage: state.confirm.warningMessage
});

const mapDispatchToProps = { confirmAction, cancelAction };

export default connect(mapStateToProps, mapDispatchToProps)(Confirm);
