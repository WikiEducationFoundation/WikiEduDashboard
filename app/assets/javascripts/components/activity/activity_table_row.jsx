import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import DiffViewer from '../revisions/diff_viewer.jsx';

const ActivityTableRow = createReactClass({
  displayName: 'ActivityTableRow',

  propTypes: {
    rowId: PropTypes.number,
    diffUrl: PropTypes.string,
    revisionDateTime: PropTypes.string,
    reportUrl: PropTypes.string,
    revisionScore: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number
    ]),
    articleUrl: PropTypes.string,
    talkPageLink: PropTypes.string,
    author: PropTypes.string,
    title: PropTypes.string,
    revision: PropTypes.object,
    isOpen: PropTypes.bool,
    toggleDrawer: PropTypes.func
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
