import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { GALLERY_VIEW } from '../../constants';
import UploadList from '../uploads/upload_list.jsx';


const UserUploads = createReactClass({
  propTypes: {
    uploads: PropTypes.array
  },

  render() {
    let uploadList = (<UploadList uploads={this.props.uploads} view={GALLERY_VIEW} />);
    if (this.props.uploads.length === 0) {
      uploadList = (<span>{I18n.t('courses.user_uploads_none')}</span>);
    }
    return (
      <div id="recent-uploads">
        <h3>Recent Uploads</h3>
        {uploadList}
      </div>
    );
  }
});

export default UserUploads;
