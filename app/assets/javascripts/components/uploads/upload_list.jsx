import React from 'react';
import PropTypes from 'prop-types';
import Editable from '../high_order/editable.jsx';
import Upload from './upload.jsx';
import UploadStore from '../../stores/upload_store.js';
import ServerActions from '../../actions/server_actions.js';
//import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({ uploads: UploadStore.getModels() });

let elements;
//const none_message={CourseUtils.i18n('uploads_none', course.string_prefix)}
const UploadList = ({ uploads }) => {
  if (uploads.length > 1) {
      elements = uploads.map(upload => {
        return <Upload upload={upload} key={upload.id} />;
    });
  } else {
      elements = (<div className="none"><p>There is no image
      or other media file contributed to Wikimedia Commons.</p></div>);
}

  return (
    <div className="gallery">
      {elements}
    </div>
  );
};


UploadList.propTypes = {
  uploads: PropTypes.array,
  course: PropTypes.object
};

export default Editable(UploadList, [UploadStore], ServerActions.saveUploads, getState);
