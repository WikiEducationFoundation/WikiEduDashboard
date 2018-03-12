import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import Upload from '../uploads/upload.jsx';

const UploadTable = createReactClass({
  displayName: 'UploadTable',

  propTypes: {
    loading: PropTypes.bool,
    uploads: PropTypes.array,
    headers: PropTypes.array
  },

  sortItems(e) {
    this.props.onSort(e.currentTarget.getAttribute("data-sort-key"));
  },

  _renderUploads() {
    return this.props.uploads.map((upload) => {
      return (
        <Upload upload={upload} key={upload.id} linkUsername={true} />
      );
    });
  },

  _renderHeaders() {
    return this.props.headers.map((header) => {
      if (header.key !== 'image') {
        return (
          <th key={header.key} style={header.style || {}} onClick={this.sortItems} className="sortable asc" data-sort-key={header.key}>
            {header.title}
            <span className="sortable-indicator" />
          </th>
        );
      }
      return (
        <th key={header.key} style={header.style || {}} className="sortable">
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

    return (
      <table className="uploads table table--sortable">
        <tbody>
          {uploads}
        </tbody>
      </table>
    );
  }
});

export default UploadTable;
