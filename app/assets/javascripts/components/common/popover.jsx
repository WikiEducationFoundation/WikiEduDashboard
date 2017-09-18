import React from 'react';

const Popover = React.createClass({
  displayName: 'Popover',

  propTypes: {
    right_aligned: React.PropTypes.bool,
    is_open: React.PropTypes.bool,
    edit_row: React.PropTypes.node,
    rows: React.PropTypes.node
  },

  render() {
    let divClass = 'pop';
    if (this.props.is_open) {
      divClass += ' open';
    }
    if (this.props.right_aligned) {
      divClass += ' right-aligned';
    }
    return (
      <div className={divClass}>
        <table>
          <tbody>
            {this.props.edit_row}
            {this.props.rows}
          </tbody>
        </table>
      </div>
    );
  }
});

export default Popover;
