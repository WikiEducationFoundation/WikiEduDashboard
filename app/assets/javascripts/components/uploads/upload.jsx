import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import moment from 'moment';

const Upload = createReactClass({
  displayName: 'Upload',

  propTypes: {
    upload: PropTypes.object,
    linkUsername: PropTypes.bool,
  },

  getInitialState() {
    return {
      width: null,
      height: null,
    };
  },

  componentWillMount() {
    this.setImageFile();
  },

  setImageFile() {
    let imageFile = this.props.upload.thumburl;
    if (this.props.upload.deleted) {
      imageFile = '/assets/images/deleted_image.svg';
    }
    this.setState({ imageFile: imageFile }, () => {
      this.setImageDimensions();
    });
  },

  setImageDimensions() {
    const img = new Image();
    img.src = this.state.imageFile;
    const component = this;
    img.onload = function () {
      component.setState({ width: this.width, height: this.height });
    };
  },

  render() {
    const fileName = this.props.upload.file_name;
    let uploader;
    if (this.props.linkUsername) {
      const profileLink = `/users/${encodeURIComponent(this.props.upload.uploader)}`;
      uploader = <a href={profileLink} target="_blank">{this.props.upload.uploader}</a>;
    } else {
      uploader = this.props.upload.uploader;
    }

    let usage = '';
    if (this.props.upload.usage_count) {
        usage = `${this.props.upload.usage_count} ${I18n.t('uploads.usage_count')}`;
      }

    const uploadDivStyle = {
      width: this.state.width * 250 / this.state.height,
      flexGrow: this.state.width * 250 / this.state.height,
    };

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

    if (this.props.isTabularView) {
      return (
        <tr className="upload">
          <td>
            <a href={this.props.upload.url} target="_blank">
              <img src={this.state.imageFile} alt={fileName} />
            </a>
            {details}
          </td>
          <td className="desktop-only-tc">
            <a href={this.props.upload.url} target="_blank">{fileName}</a>
          </td>
          <td className="desktop-only-tc">{uploader}</td>
          <td className="desktop-only-tc">{usage}</td>
          <td className="desktop-only-tc">{moment(this.props.upload.uploaded_at).format('YYYY-MM-DD   h:mm A')}</td>
        </tr>
      );
    }

    else {
      return (
        <div className="upload" style={uploadDivStyle} >
          <img src={this.state.imageFile} alt={fileName} />
          <div className="info">
            <p className="usage"><b>{usage}</b></p>
            <p><b><a href={this.props.upload.url} target="_blank">{fileName}</a></b></p>
            <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
            <p>{moment(this.props.upload.uploaded_at).format('YYYY/MM/DD h:mm a')}</p>
          </div>
        </div>
      );
    }
  },
});

const mapStateToProps = state => ({
  isTabularView: state.uploads.isTabularView,
});

export default connect(mapStateToProps)(Upload);
