import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const TrainingApp = createReactClass({
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
