import React from 'react';
import moment from 'moment';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import UploadViewer from './upload_viewer.jsx';
import Modal from '../common/modal.jsx';
import PropTypes from 'prop-types';

class Upload extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      width: null,
      height: null,
      isUploadViewerOpen: false,
    };
    this.setImageFile = this.setImageFile.bind(this);
    this.setImageDimensions = this.setImageDimensions.bind(this);
    this.isUploadViewerOpen = this.isUploadViewerOpen.bind(this);
  }

  componentDidMount() {
    this.setImageFile();
  }

  static getDerivedStateFromProps(props, state) {
    if (!state.imageFile) {
      return { imageFile: props.upload.thumburl };
    }
    return null;
  }

  setImageFile() {
    let imageFile = this.props.upload.thumburl;
    if (this.props.upload.deleted) {
      imageFile = '/assets/images/deleted_image.svg';
    }
    this.setState({ imageFile: imageFile }, () => {
      this.setImageDimensions();
    });
  }

  setImageDimensions() {
    const img = new Image();
    img.src = this.state.imageFile;
    const component = this;
    img.onload = function () {
      component.setState({ width: this.width, height: this.height });
    };
  }

  isUploadViewerOpen() {
    this.setState({ isUploadViewerOpen: !this.state.isUploadViewerOpen });
  }

  render() {
    let fileName = this.props.upload.file_name;
    if (fileName.length > 50) {
      fileName = `${fileName.substring(0, 50)}...`;
    }
    let uploader;
    if (this.props.linkUsername) {
      const profileLink = `/users/${encodeURIComponent(this.props.upload.uploader)}`;
      uploader = <a href={profileLink} onClick={event => event.stopPropagation()} target="_blank">{this.props.upload.uploader}</a>;
    } else {
      uploader = this.props.upload.uploader;
    }

    let usage = '';
    if (this.props.upload.usage_count) {
        usage = `${I18n.t('uploads.usage_count_gallery_tile', { usage_count: this.props.upload.usage_count })}`;
      }

    let uploadDivStyle;
    if (this.state.width && this.state.height) {
      uploadDivStyle = {
        width: (this.state.width * 250) / this.state.height,
        flexGrow: (this.state.width * 250) / this.state.height,
      };
    }

    let details;
    if (this.props.upload.usage_count > 0) {
      details = (
        <p className="tablet-only">
          <span>{this.props.upload.uploader}</span>
          <span>&nbsp;|&nbsp;</span>
          <span>Usages: {this.props.upload.usage_count}</span>
        </p>
      );
    } else {
      details = (
        <p className="tablet-only"><span>{this.props.upload.uploader}</span></p>
      );
    }

    let credit = '<div class="results-loading"> &nbsp; &nbsp; </div>';
    if (this.props.upload.credit) {
      credit = this.props.upload.credit;
    }

    if (this.state.isUploadViewerOpen) {
      if (this.props.view === LIST_VIEW) {
        return (
          <tr>
            <td>
              <Modal>
                <UploadViewer closeUploadViewer={this.isUploadViewerOpen} upload={this.props.upload} imageFile={this.state.imageFile} />
              </Modal>
            </td>
          </tr>
        );
      }
      return (
        <Modal>
          <UploadViewer closeUploadViewer={this.isUploadViewerOpen} upload={this.props.upload} imageFile={this.state.imageFile} />
        </Modal>
      );
    }


    if (this.props.view === LIST_VIEW) {
      usage = `${this.props.upload.usage_count} ${I18n.t('uploads.usage_count')}`;
      return (
        <tr className="upload list-view" onClick={this.isUploadViewerOpen}>
          <td>
            <img src={this.state.imageFile} alt={fileName} />
            {details}
          </td>
          <td className="desktop-only-tc">
            <a onClick={event => event.stopPropagation()} href={this.props.upload.url} target="_blank">{fileName}</a>
          </td>
          <td className="desktop-only-tc">{uploader}</td>
          <td className="desktop-only-tc">{this.props.upload.usage_count}</td>
          <td className="desktop-only-tc">{moment(this.props.upload.uploaded_at).format('YYYY-MM-DD   h:mm A')}</td>
          <td className="desktop-only-tc" dangerouslySetInnerHTML={{ __html: credit }} />
        </tr>
      );
    } else if (this.props.view === GALLERY_VIEW) {
      return (
        <div className="upload" style={uploadDivStyle} onClick={this.isUploadViewerOpen} >
          <img src={this.state.imageFile} alt={fileName} />
          <div className="info">
            <p className="usage"><b>{usage}</b></p>
            <p><b><a href={this.props.upload.url} target="_blank" onClick={event => event.stopPropagation()}>{fileName}</a></b></p>
            <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
            <p><b>{I18n.t('uploads.uploaded_on')}</b>&nbsp;{moment(this.props.upload.uploaded_at).format('YYYY/MM/DD h:mm a')}</p>
          </div>
        </div>
      );
    } else if (this.props.view === TILE_VIEW) {
      return (
        <div className="tile-container" onClick={this.isUploadViewerOpen}>
          <div className="tile">
            <img src={this.state.imageFile} alt={fileName} />
            <div className="info">
              <p className="usage"><b>{usage}</b></p>
              <p><b><a href={this.props.upload.url} target="_blank" onClick={event => event.stopPropagation()}>{fileName}</a></b></p>
              <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
              <p>
                <b>{I18n.t('uploads.uploaded_on')}</b>&nbsp;{moment(this.props.upload.uploaded_at).format('YYYY/MM/DD h:mm a')}
              </p>
            </div>
          </div>
        </div>
      );
    }
  }
}

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool,
};

export default Upload;
