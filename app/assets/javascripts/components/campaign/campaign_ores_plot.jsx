import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from '../articles/course_quality_progress_graph';

const CampaignOresPlot = createReactClass({
  displayName: 'CampaignOresPlot',

  propTypes: {
    params: PropTypes.object
  },

  getInitialState() {
    return {
      show: false,
      articleData: null,
      loading: true
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

  shouldShowButton() {
    // Do not show it if there are zero articles edited, or it's not an en-wiki course.
    return this.isSupportedWiki() && this.props.course.edited_count !== '0';
  },

  fetchFilePath() {
    $.ajax({
      url: `/campaigns/${this.props.params.campaign_slug}/ores_data.json`,
      success: (data) => {
        this.setState({ articleData: data.ores_plot, loading: false });
      }
    });
  },

  render() {
    if (this.state.show) {
      if (this.state.articleData) {
        return (
          <div className="ores-plot">
            <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={400} articleData={this.state.articleData} />
            <p>
              This graph visualizes, in aggregate, how much articles developed from
              when campaign participants first edited them until now. The <em>Structural Completeness </em>
              rating is based on a machine learning project (<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>)
              that estimates an article&apos;s quality rating based on the amount of
              prose, the number of wikilinks, images and section headers, and other features.
            </p>
          </div>
        );
      }
      if (this.state.loading) {
        return <div onClick={this.hide}><Loading /></div>;
      }
      return <div>No Structural Completeness data available</div>;
    }
    return (<button className="button small" onClick={this.show}>Change in Structural Completeness</button>);
  }
});

export default CampaignOresPlot;
