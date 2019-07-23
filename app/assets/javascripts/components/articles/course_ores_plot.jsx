import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from './course_quality_progress_graph';
import { ORESSupportedWiki } from '../../utils/article_finder_language_mappings';

const CourseOresPlot = createReactClass({
  displayName: 'CourseOresPlot',

  propTypes: {
    course: PropTypes.object
  },

  getInitialState() {
    return {
      show: false,
      articleData: null,
      refreshedData: null,
      loading: true,
      refresh: false
    };
  },

  show() {
    if (!this.state.filePath) {
      this.fetchFilePath();
    }
    return this.setState({ show: true });
  },

  refresh() {
    this.setState({ refreshedData: null });
    this.fetchFile();
    return this.setState({ show: false, refresh: true });
  },

  hide() {
    return this.setState({ show: false });
  },

  isSupportedWiki() {
    const wiki = this.props.course.home_wiki;
    if (!wiki) { return false; }
    return ORESSupportedWiki.languages.includes(wiki.language) && wiki.project === 'wikipedia';
  },

  shouldShowButton() {
    // Do not show it if there are zero articles edited, or it's not an en-wiki course.
    return this.isSupportedWiki() && this.props.course.edited_count !== '0';
  },

  fetchFile() {
    $.ajax({
      url: `/courses/${this.props.course.slug}/refresh_ores_data.json`,
      success: (data) => {
        this.setState({ refreshedData: data.ores_plot, loading: false });
      }
    });
  },

  fetchFilePath() {
    $.ajax({
      url: `/courses/${this.props.course.slug}/ores_plot.json`,
      success: (data) => {
        this.setState({ articleData: data.ores_plot, loading: false });
      }
    });
  },

  displayGraph(data) {
    return (
      <div className="ores-plot">
        <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={200} articleData={data} />
        <button className="button small" onClick={this.refresh}>Refresh Cached Data</button>
        <p>
          This graph visualizes, in aggregate, how much articles developed from
          when students first edited them until now. The <em>Structural Completeness </em>
          rating is based on a machine learning project (<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>)
          that estimates an article&apos;s quality rating based on the amount of
          prose, the number of wikilinks, images and section headers, and other features.
        </p>
      </div>
    );
  },

  loadgraph() {
    if (this.state.loading) {
      return <div onClick={this.hide}><Loading /></div>;
    }
    return <div>No Structural Completeness data available</div>;
  },

  render() {
    if (!this.shouldShowButton()) { return <div />; }

    if (this.state.refresh) {
      if (this.state.refreshedData) {
        return (
          this.displayGraph(this.state.refreshedData)
        );
      }
      this.loadgraph();
    }

    if (this.state.show) {
      if (this.state.articleData) {
        return (
          this.displayGraph(this.state.articleData)
        );
      }
      this.loadgraph();
    }
    return (<button className="button small" onClick={this.show}>Change in Structural Completeness</button>);
  }
});

export default CourseOresPlot;
