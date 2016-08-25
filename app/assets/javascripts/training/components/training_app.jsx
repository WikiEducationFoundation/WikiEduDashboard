import React from 'react';

const TrainingApp = React.createClass({
  displayName: 'TrainingApp',

  propTypes: {
    children: React.PropTypes.node
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
