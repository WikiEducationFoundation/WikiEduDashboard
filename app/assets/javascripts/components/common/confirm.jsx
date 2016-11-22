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
      <Modal>
        <div className="confirm-modal modal">
          {this.props.message}
          <br />
          <br />
          <div className="pop_container pull-right">
            <button className="button ghost-button" onClick={this.onCancel}>Cancel</button>
            <button className="button dark" onClick={this.onConfirm}>Yes</button>
          </div>
        </div>
      </Modal>
    );
  }
});

export default Confirm;
