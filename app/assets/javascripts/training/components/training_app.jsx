import React from 'react';
import PropTypes from 'prop-types';

const TrainingApp = React.createClass({
  displayName: 'TrainingApp',

  propTypes: {
    children: PropTypes.node
  },

  render() {
    return (
      <div>
        {this.props.children}
      </div>
    );
  }
}
);

export default TrainingApp;
