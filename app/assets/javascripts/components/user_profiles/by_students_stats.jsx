import React from 'react';
import WordCountGraph from './graphs/by_students_graphs/word_count_graph.jsx';
import ViewsCountGraph from './graphs/by_students_graphs/views_count_graph.jsx';
import ArticlesEditedGraph from './graphs/by_students_graphs/articles_edited_graph.jsx';
import ArticlesCreatedGraph from './graphs/by_students_graphs/articles_created_graph.jsx';
import CommmonUploadsGraph from './graphs/by_students_graphs/common_uploads_graph.jsx';
import Loading from '../common/loading.jsx';

const ByStudentsStats = React.createClass({
  propTypes: {
    username: React.PropTypes.string,
    stats: React.PropTypes.object,
    statsData: React.PropTypes.object,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
  },
  getInitialState() {
    return {
      selectedGraph: 'word_count'
    };
  },

  setWordCountGraph() {
    this.setState({
      selectedGraph: 'word_count'
    });
  },

  setViewsCountGraph() {
    this.setState({
      selectedGraph: 'views_count'
    });
  },

  setArticlesEditedGraph() {
    this.setState({
      selectedGraph: 'articles_edited'
    });
  },

  setArticlesCreatedGraph() {
    this.setState({
      selectedGraph: 'articles_created'
    });
  },

  setCommonsUploadsGraph() {
    this.setState({
      selectedGraph: 'commons_uploads'
    });
  },

  render() {
    let statsVisualizations;
    if (this.state.selectedGraph === 'word_count')
    {
      if (this.props.statsData != null) {
        console.log('this.props.stats.word_count');
        console.log(this.props.stats.word_count);
        statsVisualizations = (
          <WordCountGraph
            statsData = {this.props.statsData.word_count}
            graphWidth = {this.props.graphWidth}
            graphHeight = {this.props.graphHeight}
          />
         );
      }
      else {
        statsVisualizations = <Loading />;
      }
    }
    else if (this.state.selectedGraph === 'views_count') {
      statsVisualizations = (
        <ViewsCountGraph
          statsData = {this.props.statsData.views_count}
          graphWidth = {this.props.graphWidth}
          graphHeight = {this.props.graphHeight}
        />
     );
    }
    else if (this.state.selectedGraph === 'articles_edited') {
      statsVisualizations = (
        <ArticlesEditedGraph
          statsData = {this.props.statsData.articles_edited}
          graphWidth = {this.props.graphWidth}
          graphHeight = {this.props.graphHeight}
        />
      );
    }
    else if (this.state.selectedGraph === 'articles_created') {
      statsVisualizations = (
        <ArticlesCreatedGraph
          statsData = {this.props.statsData.articles_created}
          graphWidth = {this.props.graphWidth}
          graphHeight = {this.props.graphHeight}
        />
        );
    }
    else if (this.state.selectedGraph === 'commons_uploads') {
      statsVisualizations = (
        <CommmonUploadsGraph
          statsData = {this.props.statsData.articles_created}
          graphWidth = {this.props.graphWidth}
          graphHeight = {this.props.graphHeight}
        />
    );
    }
    return (
      <div className = "user_stats">
        <h5>
          {I18n.t('user_profiles.instructors_student_impact', { username: this.props.username })}
        </h5>
        <div className= "stat-display">
          <div onClick={this.setWordCountGraph} className= "stat-display__stat button">
            <div className="stat-display__value">
              {this.props.stats.word_count}
            </div>
            <small>
              {I18n.t('metrics.word_count')}
            </small>
          </div>
          <div onClick={this.setViewsCountGraph} className= "stat-display__stat button">
            <div className="stat-display__value">
              {this.props.stats.view_sum}
            </div>
            <small>
              {I18n.t('metrics.view_count_description')}
            </small>
          </div>
          <div onClick={this.setArticlesEditedGraph} className= "stat-display__stat button">
            <div className="stat-display__value">
              {this.props.stats.article_count}
            </div>
            <small>
              {I18n.t('metrics.articles_edited')}
            </small>
          </div>
          <div onClick={this.setArticlesCreatedGraph} className= "stat-display__stat button">
            <div className="stat-display__value">
              {this.props.stats.new_article_count}
            </div>
            <small>
              {I18n.t('metrics.articles_created')}
            </small>
          </div>
          <div onClick={this.setCommonsUploadsGraph} className ="stat-display__stat tooltip-trigger button">
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
            <div className="stat-display__value">
              {this.props.stats.upload_count}
            </div>
            <small>
              {I18n.t('metrics.upload_count')}
            </small>
            <div className="tooltip dark">
              <h4>
                {this.props.stats.uploads_in_use_count}
              </h4>
              <p>
                {I18n.t("metrics.uploads_in_use_count", { count: this.props.stats.uploads_in_use_count })}
              </p>
              <h4>{this.props.stats.upload_usage_count}</h4>
              <p>
                {I18n.t("metrics.upload_usages_count", { count: this.props.stats.upload_usage_count })}
              </p>
            </div>
          </div>
        </div>
        {statsVisualizations}
      </div>
    );
  }
});

export default ByStudentsStats;
