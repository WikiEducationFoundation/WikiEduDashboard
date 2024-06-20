import React from 'react';
import PropTypes from 'prop-types';
import Upload from './upload.jsx';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

const UploadList = ({ uploads, view, sortBy, loadingUploads, totalUploadsCount }) => {
  let elements;
  let noUploadsMessage;
  if (uploads.length > 0) {
    elements = uploads.map(upload => (
      <Upload upload={upload} view={view} key={upload.id} linkUsername={true} />
    ));
  } else if (!loadingUploads && totalUploadsCount > 0 && uploads.length === 0) {
    elements = [];
    noUploadsMessage = <div className="none text-center"><p>{I18n.t('courses_generic.user_uploads_none')}</p></div>;
  } else if (!loadingUploads && uploads.length === 0) {
    elements = [];
    noUploadsMessage = <div className="none text-center"><p>{I18n.t('courses_generic.uploads_none')}</p></div>;
  } else {
    elements = <div style={{ width: '100%' }}><Loading /></div>;
  }

  const keys = {
    image: {
      label: I18n.t('uploads.image'),
      desktop_only: false
    },
    file_name: {
      label: I18n.t('uploads.file_name'),
      desktop_only: true
    },
    uploaded_by: {
      label: I18n.t('uploads.uploader'),
      desktop_only: true
    },
    usage_count: {
      label: I18n.t('uploads.usage_count'),
      desktop_only: true,
      info_key: 'uploads.usage_doc'
    },
    date: {
      label: I18n.t('uploads.uploaded_at'),
      desktop_only: true,
      info_key: 'uploads.time_doc'
    },
    credit: {
      label: I18n.t('uploads.credit'),
      desktop_only: true,
    }
  };

  let uploadsView;

  if (view === GALLERY_VIEW) {
    uploadsView = elements.length === 0 ? <div className="list-view">{noUploadsMessage}</div> : <div className="gallery-view"> {elements} </div>;
  }

  if (view === LIST_VIEW) {
    if (elements.length > 0) {
      uploadsView = (
        <div className="list-view">
          <List
            elements={elements}
            keys={keys}
            table_key="uploads"
            sortBy={sortBy}
          />
        </div>);
    } else {
      uploadsView = <div className="list-view">{noUploadsMessage}</div>;
    }
  }

  if (view === TILE_VIEW) {
    uploadsView = (
      <div className="tile-view">
        {uploads.length > 0 ? elements : noUploadsMessage}
      </div>
    );
  }

  return (
    <div>
      {uploadsView}
    </div>
  );
};

UploadList.propTypes = {
  uploads: PropTypes.array,
  view: PropTypes.string,
  sortBy: PropTypes.func,
  loadingUploads: PropTypes.bool,
  totalUploadsCount: PropTypes.number,
};

export default UploadList;
