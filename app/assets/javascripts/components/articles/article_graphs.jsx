import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Wp10Graph from './wp10_graph.jsx';
import EditSizeGraph from './edit_size_graph.jsx';
import Loading from '../common/loading.jsx';
import request from '../../utils/request';


const ArticleGraphs = createReactClass({
  displayName: 'ArticleGraphs',

  propTypes: {
    article: PropTypes.object
  },

  getInitialState() {
    return {
      showGraph: false,
      selectedRadio: 'wp10_score',
      articleData: null
    };
  },

  componentDidMount() {
    this.ref = React.createRef();
  },

  componentDidUpdate(_, prevState) {
    if (this.state.showGraph && !prevState.showGraph) {
      // Add event listener when the component is visible
      document.addEventListener('mousedown', this.handleClickOutside);
    }
    if (!this.state.showGraph && prevState.showGraph) {
      // remove event listener when the component is hidden
      document.removeEventListener('mousedown', this.handleClickOutside);
    }
  },

  getData() {
    if (this.state.articleData) { return; }

    const articleId = this.props.article.id;
    const articledataUrl = `/articles/article_data.json?article_id=${articleId}`;
    request(articledataUrl)
      .then(resp => resp.json())
      .then((data) => {
        this.setState({ articleData: data });
      });
  },

  handleClickOutside(event) {
    const element = this.ref.current;
    if (element && !element.contains(event.target)) {
      this.hideGraph();
    }
  },

  showGraph() {
    this.getData();
    this.setState({ showGraph: true });
  },

  handleRadioChange(event) {
    this.setState({
      selectedRadio: event.currentTarget.value
    });
  },

  hideGraph() {
    this.state.articleData = null;
    this.setState({ showGraph: false });
  },

  graphId() {
    return `vega-graph-${this.props.article.id}`;
  },

  render() {
    let style = 'hidden';
    if (this.state.showGraph) {
      style = '';
    }

    let graph;
    let editSize;
    let radioInput;
    const graphWidth = 500;
    const graphHeight = 300;
    const className = `vega-graph ${style}`;

    if (this.state.articleData != null) {
      // Only render the wp10 graph radio button if the data includes wp10 / article completeness scores
      if (this.state.articleData[0].wp10) {
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
        if (this.state.selectedRadio === 'wp10_score') {
          graph = (
            <Wp10Graph
              graphid = {this.graphId()}
              graphWidth = {graphWidth}
              graphHeight = {graphHeight}
              articleData = {this.state.articleData}
            />
          );
        } else {
          graph = (
            <EditSizeGraph
              graphid ={this.graphId()}
              graphWidth = {graphWidth}
              graphHeight = {graphHeight}
              articleData = {this.state.articleData}
            />
          );
        }
      } else {
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
      } // Display the loading element if articleData is not available
     } else {
      graph = <Loading />;
    }

    return (
      <a onClick={this.showGraph} className="inline">
        {I18n.t('articles.article_development')}
        <div className={className} ref={this.ref}>
          <div className="radio-row">
            {radioInput}
            {editSize}
          </div>
          {graph}
        </div>
      </a>
    );
  }
});

export default ArticleGraphs;
