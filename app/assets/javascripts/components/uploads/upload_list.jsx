import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Upload from './upload.jsx';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import List from '../common/list.jsx';
import Loading from '../common/loading.jsx';

const UploadList = createReactClass({
  displayName: 'UploadList',

  propTypes: {
    uploads: PropTypes.array,
    view: PropTypes.string,
    sortBy: PropTypes.func,
  },

  render() {
    const uploads = this.props.uploads;
    let elements;
    if (uploads.length > 0) {
      elements = uploads.map((upload) => {
        return <Upload upload={upload} view={this.props.view} key={upload.id} linkUsername={true} />;
      });
    } else if (!this.props.loadingUploads && this.props.totalUploadsCount > 0 && uploads.length === 0) {
      elements = (<div className="none"><p>{I18n.t('courses_generic.user_uploads_none')}</p></div>);
    } else if (!this.props.loadingUploads && uploads.length === 0) {
      elements = (<div className="none"><p>{I18n.t('courses_generic.uploads_none')}</p></div>);
    } else {
      elements = (<div style={{ width: '100%' }}><Loading /></div>);
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

    if (this.props.view === GALLERY_VIEW) {
      uploadsView = (
        <div className="gallery">
          {elements}
        </div>
      );
    }

    if (this.props.view === LIST_VIEW) {
      uploadsView = (
        <List
          elements={elements}
          keys={keys}
          table_key="uploads"
          sortBy={this.props.sortBy}
          none_message={I18n.t('courses_generic.uploads_none')}
        />
      );
    }

    if (this.props.view === TILE_VIEW) {
      uploadsView = (
        <div className="tile-view">
          {elements}
        </div>
      );
    }

    return (
      <div>
        {uploadsView}
      </div>
    );
  }
});

export default UploadList;
