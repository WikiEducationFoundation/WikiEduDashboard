import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from '../articles/course_quality_progress_graph';

const CampaignOresPlot = createReactClass({
  displayName: 'CampaignOresPlot',

  propTypes: {
    match: PropTypes.object
  },

  getInitialState() {
    return {
      show: false,
      articleData: null,
      loading: true
    };
  },

  componentDidMount() {
     // This clears Rails parts of the previous pages, when changing Campagn tabs
    if (document.getElementById('users')) {
      document.getElementById('users').innerHTML = '';
    }
    if (document.getElementById('campaign-articles')) {
      document.getElementById('campaign-articles').innerHTML = '';
    }
    if (document.getElementById('courses')) {
      document.getElementById('courses').innerHTML = '';
    }
    if (document.getElementById('overview-campaign-details')) {
      document.getElementById('overview-campaign-details').innerHTML = '';
    }
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
      url: `/campaigns/${this.props.match.params.campaign_slug}/ores_data.json`,
      success: (data) => {
        this.setState({ articleData: data.ores_plot, loading: false });
      }
    });
  },

  render() {
    if (this.state.show) {
      if (this.state.articleData) {
        return (
          <div id="ores" className="ores-plot">
            <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={400} articleData={this.state.articleData} />
            <p>
              This graph visualizes, in aggregate, how much articles developed from
              before campaign participants first edited them until the most recent campagin edits. The <em>Structural Completeness </em>
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
    return (
      <button className="button small" onClick={this.show}>Change in Structural Completeness</button>
    );
  }
});

export default CampaignOresPlot;
