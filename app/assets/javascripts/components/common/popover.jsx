import React from 'react';
import PropTypes from 'prop-types';

const Popover = (props) => {
  let divClass = 'pop';
  // eslint-disable-next-line
  if (props.is_open) {
    divClass += ' open';
  }

  return (
    <div className={divClass}>
      <table>
        <tbody>
          {props.edit_row}
          {props.rows}
        </tbody>
      </table>
    </div>
  );
};

Popover.propTypes = {
  is_open: PropTypes.bool,
  edit_row: PropTypes.node,
  rows: PropTypes.node
};

export default Popover;
