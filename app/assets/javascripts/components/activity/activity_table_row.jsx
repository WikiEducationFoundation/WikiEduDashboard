import React from 'react';
import UIStore from '../../stores/ui_store.coffee';
import UIActions from '../../actions/ui_actions.coffee';

const ActivityTableRow = React.createClass({

  propTypes: {
    key: React.PropTypes.string,
    rowId: React.PropTypes.string,
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
    title: React.PropTypes.string
  },

  mixins: [UIStore.mixin],

  getInitialState() {
    return { is_open: false };
  },

  storeDidChange() {
    return this.setState({ is_open: UIStore.getOpenKey() === `drawer_${this.props.rowId}` });
  },

  openDrawer() {
    return UIActions.open(`drawer_${this.props.rowId}`);
  },

  render() {
    let className = 'activity-table-row';
    let revisionDateTime;
    let col2;
    className += this.state.is_open ? ' open' : ' closed';

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

    return (
      <tr className={className} onClick={this.openDrawer} key={this.props.key}>
        <td>
          <a href={this.props.articleUrl}>{this.props.title}</a>
        </td>
        {col2}
        <td>
          <a href={this.props.talkPageLink}>{this.props.author}</a>
        </td>
        <td>
          {revisionDateTime}
        </td>
        <td>
          <button className="icon icon-arrow"></button>
        </td>
      </tr>
    );
  }
});

export default ActivityTableRow;
