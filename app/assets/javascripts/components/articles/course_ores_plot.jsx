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

  shouldShowButton() {
    // Do not show it if there are zero articles edited, or it's not an en-wiki course.
    return this.isEnwiki() && this.props.course.edited_count !== '0';
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
    if (!this.shouldShowButton()) { return <div />; }

    if (this.state.show) {
      if (this.state.filePath) {
        return (
          <div className="ores-plot">
            <img className="ores-plot" src={`/${this.state.filePath}`} onClick={this.hide} alt="ORES plot" />
            <p>
              This graph visualizes, in aggregate, how much articles developed from
              when students first edited them until now. The <em>Structural Completeness </em>
              rating is based on a machine learning project (<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>)
              that estimates an article&apos;s quality rating based on the amount of
              prose, the number of wikilinks, images and section headers, and other features.
            </p>
          </div>
        );
      }
      return <div onClick={this.hide}><Loading /></div>;
    }
    return (<button className="button small" onClick={this.show}>Change in Structural Completeness</button>);
  }
});

export default CourseOresPlot;
