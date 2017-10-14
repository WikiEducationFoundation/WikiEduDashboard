import React from 'react';
import PropTypes from 'prop-types';
import Editable from '../high_order/editable.jsx';

import List from '../common/list.jsx';
import Upload from './upload.jsx';
import UploadStore from '../../stores/upload_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({ uploads: UploadStore.getModels() });

const UploadList = ({ uploads, course }) => {
  const elements = uploads.map(upload => {
    return <Upload upload={upload} key={upload.id} />;
  });

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
      label: I18n.t('uploads.uploaded_by'),
      desktop_only: true
    },
    usage_count: {
      label: I18n.t('uploads.usage_count'),
      desktop_only: true
    },
    date: {
      label: I18n.t('uploads.datetime'),
      desktop_only: true,
      info_key: 'uploads.time_doc'
    }
  };

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="uploads"
      none_message={CourseUtils.i18n('uploads_none', course.string_prefix)}
      store={UploadStore}
    />
  );
};

UploadList.propTypes = {
  uploads: PropTypes.array,
  course: PropTypes.object
};

export default Editable(UploadList, [UploadStore], ServerActions.saveUploads, getState);
