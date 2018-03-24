import React from 'react';
import PropTypes from 'prop-types';
import Upload from './upload.jsx';
import CourseUtils from '../../utils/course_utils.js';

const UploadList = ({ uploads, course }) => {
  let elements;
  if (uploads.length > 0) {
      elements = uploads.map(upload => {
        return <Upload upload={upload} key={upload.id} />;
    });
  } else {
      elements = (<div className="none"><p>{CourseUtils.i18n('uploads_none', course.string_prefix)}</p></div>);
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

export default UploadList;
