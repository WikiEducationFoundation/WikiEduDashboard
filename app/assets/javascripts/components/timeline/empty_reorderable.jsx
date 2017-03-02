import React from 'react';

import Reorderable from '../high_order/reorderable.jsx';

const EmptyReorderable = React.createClass({
  displayName: 'EmptyReorderable',

  propTypes: {

  },

  render() {
    return (
      <li>
        No blocks in this week
      </li>
    );
  }
});

export default Reorderable(EmptyReorderable, 'block', 'onDrop');

