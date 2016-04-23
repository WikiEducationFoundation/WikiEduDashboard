import React from 'react';
import TransitionGroup from 'react-addons-css-transition-group';
import Loading from '../common/loading.cjsx';
import _ from 'lodash';
import moment from 'moment';
import Upload from '../uploads/upload.cjsx';

const UploadTable = React.createClass({
  displayName: 'UploadTable',

  propTypes: {
    loading: React.PropTypes.bool,
    uploads: React.PropTypes.array,
    headers: React.PropTypes.array,
    noActivityMessage: React.PropTypes.string
  },

  getInitialState() {
    return {
      uploads: this.props.uploads
    };
  },

  _renderActivites() {
    return this.state.uploads.map((upload) => {
      return (
        <Upload upload={upload} key={upload.id} />
      );
    });
  },

  _renderHeaders() {
    return this.props.headers.map((header) => {
      return (
        <th key={header.key} onClick={this.sortItems} className="sortable" data-sort-key={header.key}>
          {header.title}
        </th>
      );
    });
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const activity = this._renderActivites();
    const ths = this._renderHeaders();

    let elements = _.flatten(_.zip(activity));
    if (!elements.length) {
      elements = <tr><td colSpan="6">{this.props.noActivityMessage}</td></tr>;
    }

    return (
      <table className="activity-table list">
        <thead>
          <tr>
            {ths}
            <th></th>
          </tr>
        </thead>
        <TransitionGroup
          transitionName={'dyk'}
          component="tbody"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={500}
        >
          {elements}
        </TransitionGroup>
      </table>
    );
  }
});

export default UploadTable;
