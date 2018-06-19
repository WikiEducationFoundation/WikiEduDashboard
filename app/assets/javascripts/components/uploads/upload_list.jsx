import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Upload from './upload.jsx';

import List from '../common/list.jsx';

const UploadList = createReactClass({
  displayName: 'UploadList',

  propTypes: {
    uploads: PropTypes.array
  },

  render() {
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
    let elements;
    if (this.props.uploads.length > 0) {
      elements = this.props.uploads.map(upload => {
        return <Upload upload={upload} key={upload.id} linkUsername={true} />;
      });
    } else {
      elements = (<div className="none"><p>{I18n.t('courses_generic.uploads_none')}</p></div>);
    }

    let uploadsView = (
      <div className="gallery">
        {elements}
      </div>
    );

    if (this.props.isTabularView) {
      uploadsView = (
        <List
          elements={elements}
          keys={keys}
          table_key="uploads"
          sortBy={this.props.sortBy}
        />
      );
    }

    return (
      <div>
        {uploadsView}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  isTabularView: state.uploads.isTabularView,
});

export default connect(mapStateToProps)(UploadList);
