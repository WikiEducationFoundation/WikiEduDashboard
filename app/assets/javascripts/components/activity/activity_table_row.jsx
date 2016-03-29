import React from 'react';
import UIStore from '../../stores/ui_store.coffee';
import UIActions from '../../actions/ui_actions.coffee';

let ActivityTableRow = React.createClass({
  mixins: [UIStore.mixin],

  storeDidChange() {
    return this.setState({is_open: UIStore.getOpenKey() === (`drawer_${this.props.rowId}`)});
  },

  getInitialState() {
    return {is_open: false};
  },

  openDrawer() {
    return UIActions.open(`drawer_${this.props.rowId}`);
  },

  render() {
    let className = 'activity-table-row';
    className += this.state.is_open ? ' open' : ' closed';
    if (this.props.diffUrl) {
      var revisionDateTime = (
        <a href={this.props.diffUrl}>{this.props.revisionDateTime}</a>
      );
    } else {
      let revisionLink = this.props.revisionDateTime;
    }

    if (this.props.revisionScore) {
      var col2 = (
        <td>
          {this.props.revisionScore}
        </td>
      );
    }
    if (this.props.reportUrl) {
      var col2 = (
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
          <button className='icon icon-arrow'></button>
        </td>
      </tr>
    );
  }
});

export default ActivityTableRow;
