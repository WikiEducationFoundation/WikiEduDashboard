import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const Popover = createReactClass({
  displayName: 'Popover',

  propTypes: {
    is_open: PropTypes.bool,
    edit_row: PropTypes.node,
    rows: PropTypes.node
  },

  render() {
    let divClass = 'pop';
    if (this.props.is_open) {
      divClass += ' open';
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
