import React from 'react';
import Expandable from '../high_order/expandable.jsx';
import ArticleDetailsStore from '../../stores/article_details_store.js';
import DiffViewer from '../revisions/diff_viewer.jsx';
import ArticleViewer from '../common/article_viewer.jsx';
import ArticleGraphs from './article_graphs.jsx';

const getArticleDetails = () => ArticleDetailsStore.getArticleDetails();

const ArticleDrawer = React.createClass({
  displayName: 'ArticleDrawer',

  propTypes: {
    article: React.PropTypes.object,
    is_open: React.PropTypes.bool,
    current_user: React.PropTypes.object,
    course: React.PropTypes.object
  },

  mixins: [ArticleDetailsStore.mixin],

  getInitialState() {
    return {
      articleDetails: getArticleDetails()
    };
  },

  getKey() {
    return `drawer_${this.props.article.id}`;
  },

  storeDidChange() {
    return this.setState({
      articleDetails: getArticleDetails()
    });
  },

  render() {
    if (!this.props.is_open) { return <tr></tr>; }

    let className = 'drawer';
    className += !this.props.is_open ? ' closed' : '';

    let diffViewer;
    let articleViewer;
    // DiffViewer and ArticleViewer require articleDetails data, so user a
    // placeholder for each until the data is available.
    if (this.state.articleDetails.first_revision) {
      const showSalesforceButton = Boolean(Features.wikiEd && this.props.current_user.admin);
      diffViewer = (
        <DiffViewer
          revision={this.state.articleDetails.last_revision}
          first_revision={this.state.articleDetails.first_revision}
          showButtonLabel={I18n.t('articles.show_cumulative_changes')}
          largeButton={true}
          editors={this.state.articleDetails.editors}
          showSalesforceButton={showSalesforceButton}
          course={this.props.course}
          article={this.props.article}
        />
      );
      articleViewer = (
        <ArticleViewer article={this.props.article} users={this.state.articleDetails.editors} largeButton={true} />
      );
    } else {
      diffViewer = <button className="button dark">{I18n.t('articles.show_cumulative_changes')}</button>;
      articleViewer = <button className="button dark">{I18n.t('articles.show_current_version')}</button>;
    }

    let editedBy;
    if (this.state.articleDetails.editors) {
      editedBy = <p>{I18n.t('articles.edited_by')} {this.state.articleDetails.editors.join(', ')}</p>;
    }

    return (
      <tr className={className}>
        <td colSpan="7">
          <span />
          <table className="table">
            <tbody>
              <tr>
                <td colSpan="3">
                  {diffViewer}
                </td>
                <td colSpan="2">
                  {articleViewer}
                </td>
                <td colSpan="2">
                  <ArticleGraphs article={this.props.article} />
                </td>
              </tr>
              <tr>
                <td colSpan="7">
                  {editedBy}
                </td>
              </tr>
            </tbody>
          </table>
        </td>
      </tr>
    );
  }
});

export default Expandable(ArticleDrawer);
