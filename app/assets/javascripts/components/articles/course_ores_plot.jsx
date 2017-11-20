import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';

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

  isEnwiki() {
    const wiki = this.props.course.home_wiki;
    if (!wiki) { return false; }
    return wiki.language === 'en' && wiki.project === 'wikipedia';
  },

  fetchFilePath() {
    $.ajax({
      url: `/courses/${this.props.course.slug}/ores_plot.json`,
      success: (data) => {
        this.setState({ filePath: data.plot_path });
      }
    });
  },

  render() {
    if (!this.isEnwiki()) { return <div />; }

    if (this.state.show) {
      if (this.state.filePath) {
        return (<img className="ores-plot" src={`/${this.state.filePath}`} onClick={this.hide} />);
      }
      return <Loading />;
    }
    return (<button className="button small" onClick={this.show}>Change in Structural Completeness</button>);
  }
});

export default CourseOresPlot;
