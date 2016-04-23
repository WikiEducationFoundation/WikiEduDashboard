import React from 'react';
import TransitionGroup from 'react-addons-css-transition-group';
import Loading from '../common/loading.cjsx';
import Upload from '../uploads/upload.cjsx';

const UploadTable = React.createClass({
  displayName: 'UploadTable',

  propTypes: {
    loading: React.PropTypes.bool,
    uploads: React.PropTypes.array,
    headers: React.PropTypes.array
  },

  getInitialState() {
    return {
      uploads: this.props.uploads
    };
  },

  _renderUploads() {
    return this.state.uploads.map((upload) => {
      return (
        <Upload upload={upload} key={upload.id} />
      );
    });
  },

  _renderHeaders() {
    return this.props.headers.map((header) => {
      return (
        <th key={header.key}>
          {header.title}
        </th>
      );
    });
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const uploads = this._renderUploads();
    const ths = this._renderHeaders();

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
          {uploads}
        </TransitionGroup>
      </table>
    );
  }
});

export default UploadTable;
