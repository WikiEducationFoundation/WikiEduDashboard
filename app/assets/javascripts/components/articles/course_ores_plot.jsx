import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const CourseOresPlot = createReactClass({
  displayName: 'CourseOresPlot',

  propTypes: {
    course: PropTypes.object
  },

  getInitialState() {
    return {
      show: false,
      filePath: null
    };
  },

  show() {
    if (!this.state.filePath) {
      this.fetchFilePath();
    }
    return this.setState({ show: true });
  },

  hide() {
    return this.setState({ show: false });
  },

  render() {
    if (this.state.show) {
      return (<div onClick={this.hide}>Ohai</div>);
    }
    return (<button className="button pull-right small" onClick={this.show}>Change in Structural Completeness</button>);
  }
});

export default CourseOresPlot;
