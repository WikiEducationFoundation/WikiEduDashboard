import React from 'react';
import Modal from './modal.jsx';

const Confirm = React.createClass({
  displayName: 'Confirm',

  propTypes: {
    onConfirm: React.PropTypes.func.isRequired,
    onCancel: React.PropTypes.func.isRequired,
    message: React.PropTypes.string.isRequired
  },

  getInitialState() {
    return { open: true };
  },

  onConfirm() {
    this.setState({ open: false });
    this.props.onConfirm();
  },

  onCancel() {
    this.setState({ open: false });
    this.props.onCancel();
  },

  render() {
    if (!this.state.open) { return <div></div>; }
    return (
      <Modal modalClass="confirm-modal-overlay">
        <div className="confirm-modal">
          {this.props.message}
          <br />
          <br />
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
