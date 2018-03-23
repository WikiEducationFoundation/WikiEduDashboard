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
  },

  _renderUploads() {
    return this.props.uploads.map((upload) => {
      return (
        <Upload upload={upload} key={upload.id} linkUsername={true} />
      );
    });
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const uploads = this._renderUploads();

    return (
      <div className="gallery">
        {uploads}
      </div>
    );
  }
});


export default UploadTable;
