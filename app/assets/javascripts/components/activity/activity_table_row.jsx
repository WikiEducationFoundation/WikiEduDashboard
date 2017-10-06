import React from 'react';
import DiffViewer from '../revisions/diff_viewer.jsx';

const ActivityTableRow = React.createClass({
  displayName: 'ActivityTableRow',

  propTypes: {
    rowId: React.PropTypes.number,
    diffUrl: React.PropTypes.string,
    revisionDateTime: React.PropTypes.string,
    reportUrl: React.PropTypes.string,
    revisionScore: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.number
    ]),
    articleUrl: React.PropTypes.string,
    talkPageLink: React.PropTypes.string,
    author: React.PropTypes.string,
    title: React.PropTypes.string,
    revision: React.PropTypes.object,
    isOpen: React.PropTypes.bool,
    toggleDrawer: React.PropTypes.func
  },

  openDrawer() {
    return this.props.toggleDrawer(`drawer_${this.props.rowId}`);
  },

  render() {
    let revisionDateTime;
    let col2;
    const className = this.props.isOpen ? 'open' : 'closed';

    if (this.props.diffUrl) {
      revisionDateTime = (
        <a href={this.props.diffUrl}>{this.props.revisionDateTime}</a>
      );
    }

    if (this.props.revisionScore) {
      col2 = (
        <td>
          {this.props.revisionScore}
        </td>
      );
    }

    if (this.props.reportUrl) {
      col2 = (
        <td>
          <a href={this.props.reportUrl} target="_blank">Report</a>
        </td>
      );
    }

    let diffViewer;
    if (this.props.revision && this.props.revision.api_url) {
      diffViewer = <DiffViewer revision={this.props.revision} />;
    }

    return (
      <tr className={className} key={this.props.rowId}>
        <td onClick={this.openDrawer}>
          <a href={this.props.articleUrl}>{this.props.title}</a>
        </td>
        {col2}
        <td onClick={this.openDrawer}>
          <a href={this.props.talkPageLink}>{this.props.author}</a>
        </td>
        <td onClick={this.openDrawer}>
          {revisionDateTime}
        </td>
        <td>
          {diffViewer}
        </td>
      </tr>
    );
  }
});

export default ActivityTableRow;
