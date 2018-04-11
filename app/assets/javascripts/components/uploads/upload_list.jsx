import React from 'react';
import PropTypes from 'prop-types';
import Upload from './upload.jsx';


const UploadList = ({ uploads }) => {
  let elements;
  if (uploads.length > 0) {
      elements = uploads.map(upload => {
        return <Upload upload={upload} key={upload.id} />;
    });
  } else {
      elements = (<div className="none"><p>{I18n.t('courses_generic.uploads_none')}</p></div>);
}

  return (
    <div className="gallery">
      {elements}
    </div>
  );
};


UploadList.propTypes = {
  uploads: PropTypes.array
};

export default UploadList;
