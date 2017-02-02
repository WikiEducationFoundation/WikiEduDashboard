/* global vg */
import React from 'react';
import OnClickOutside from 'react-onclickoutside';
import Wp10Graph from './wp10_graph.jsx';
import EditSizeGraph from './edit_size_graph.jsx';
import Loading from '../common/loading.jsx';

const ArticleGraphs = React.createClass({
  displayName: 'ArticleGraphs',

  propTypes: {
    article: React.PropTypes.object
  },

  getInitialState() {
    return {
      showGraph: false,
      selectedRadio: 'wp10_score',
      articleData: null
    };
  },

  getData() {
    const articleId = this.props.article.id;
    const articledataUrl = `/articles/article_data.json?article_id=${articleId}`;
    $.ajax(
      {
        dataType: 'json',
        url: articledataUrl,
        success: (data) => {
          this.setState({
            articleData: data
          });
        }
      });
  },

  showGraph() {
    this.state.selectedRadio = 'wp10_score';
    this.getData();
    this.setState({ showGraph: true });
  },

  handleRadioChange: function (event) {
    this.setState({
      selectedRadio: event.currentTarget.value
    });
  },

  hideGraph() {
    this.state.articleData = null;
    this.setState({ showGraph: false });
  },

  handleClickOutside() {
    this.hideGraph();
  },

  graphId() {
    return `vega-graph-${this.props.article.id}`;
  },

  render() {
    let style;
    let button;
    let graph;
    let editSize;
    let radioInput;
    const graphWidth = 500;
    const graphHeight = 300;
    if (this.state.showGraph) {
      style = '';
      button = <button onClick={this.hideGraph} className="button dark">Hide graph</button>;
    } else {
      style = ' hidden';
      button = <button onClick={this.showGraph} className="button dark">Article Development</button>;
    }

    const className = `vega-graph ${style}`;

    if (this.state.articleData != null) {
      // Only render the wp10 graph radio button if it is an en.wikipedia article, since only
      // those articles have wp10 scores.
      if (this.props.article.url.match(/en.wikipedia/)) {
        radioInput = (
          <div>
            <div className="input-row">
              <input
                type="radio"
                name="wp10_score"
                value="wp10_score"
                checked={this.state.selectedRadio === 'wp10_score'}
                onChange={this.handleRadioChange}
              />
              <label htmlFor="wp10_score">{I18n.t('articles.wp10')}</label>
            </div>
            <div className="input-row">
              <input
                type="radio"
                name="edit_size"
                value="edit_size"
                checked={this.state.selectedRadio === 'edit_size'}
                onChange={this.handleRadioChange}
              />
              <label htmlFor="edit_size">{I18n.t('articles.edit_size')}</label>
            </div>
          </div>
        );
        if (this.state.selectedRadio === 'wp10_score')
        {
          graph = (
            <Wp10Graph
              graphid = {this.graphId()}
              graphWidth = {graphWidth}
              graphHeight = {graphHeight}
              articleData = {this.state.articleData}
            />
          );
        }
        else {
          graph = (
            <EditSizeGraph
              graphid ={this.graphId()}
              graphWidth = {graphWidth}
              graphHeight = {graphHeight}
              articleData = {this.state.articleData}
            />
          );
        }
      }
      else {
        editSize = (
          <p>{I18n.t('articles.edit_size')}</p>
        );
        graph = (
          <EditSizeGraph
            graphid ={this.graphId()}
            graphWidth = {graphWidth}
            graphHeight = {graphHeight}
            articleData = {this.state.articleData}
          />
        );
      }
    }
    // Display the loading element if articleData is not available
    else {
      graph = <Loading />;
    }

    return (
      <div>
        {button}
        <div className={className}>
          <div className="radio-row">
            {radioInput}
            {editSize}
          </div>
          {graph}
        </div>
      </div>
    );
  }
});

export default OnClickOutside(ArticleGraphs);
