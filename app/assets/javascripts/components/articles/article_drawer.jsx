import React from 'react';
import DiffViewer from '../revisions/diff_viewer.jsx';
import ArticleViewer from '../common/article_viewer.jsx';
import ArticleGraphs from './article_graphs.jsx';

const ArticleDrawer = React.createClass({
  displayName: 'ArticleDrawer',

  propTypes: {
    article: React.PropTypes.object,
    isOpen: React.PropTypes.bool,
    current_user: React.PropTypes.object,
    course: React.PropTypes.object,
    articleDetails: React.PropTypes.object
  },

  render() {
    if (!this.props.isOpen) { return <tr></tr>; }

    let diffViewer;
    let articleViewer;
    // DiffViewer and ArticleViewer require articleDetails data, so user a
    // placeholder for each until the data is available.
    if (this.props.articleDetails.first_revision) {
      const showSalesforceButton = Boolean(Features.wikiEd && this.props.current_user.admin);
      diffViewer = (
        <DiffViewer
          revision={this.props.articleDetails.last_revision}
          first_revision={this.props.articleDetails.first_revision}
          showButtonLabel={I18n.t('articles.show_cumulative_changes')}
          largeButton={true}
          editors={this.props.articleDetails.editors}
          showSalesforceButton={showSalesforceButton}
          course={this.props.course}
          article={this.props.article}
        />
      );
      articleViewer = (
        <ArticleViewer article={this.props.article} users={this.props.articleDetails.editors} largeButton={true} />
      );
    } else {
      diffViewer = <button className="button dark">{I18n.t('articles.show_cumulative_changes')}</button>;
      articleViewer = <button className="button dark">{I18n.t('articles.show_current_version')}</button>;
    }

    let editedBy;
    if (this.props.articleDetails.editors) {
      editedBy = <p>{I18n.t('articles.edited_by')} {this.props.articleDetails.editors.join(', ')}</p>;
    }

    return (
      <tr className="drawer">
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

export default ArticleDrawer;
