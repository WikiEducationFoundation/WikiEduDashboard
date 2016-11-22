import React from 'react';

const Confirm = React.createClass({
  displayName: 'Confirm',

  propTypes: {
    onConfirm: React.PropTypes.func,
    onCancel: React.PropTypes.func
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
        <div className="modal wizard">
          Are you sure?
          <button className="button danger" onClick={this.onCancel}>Cancel</button>
          <button className="button dark" onClick={this.onConfirm}>Yes</button>
        </div>
    );
  }
});

export default Confirm;
