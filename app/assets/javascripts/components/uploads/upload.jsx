import React from 'react';

const Upload = React.createClass({
  displayName: 'Upload',

  propTypes: {
    upload: React.PropTypes.object
  },

  render() {
    let details;
    if (this.props.upload.usages > 0) {
      details = (
        <p className="tablet-only">
          <span>{this.props.upload.uploader}</span>
          <span>&nbsp;|&nbsp;</span>
          <span>Usages: {this.props.upload.usages}</span>
        </p>
      );
    } else {
      details = (
        <p className="tablet-only"><span>{this.props.upload.uploader}</span></p>
      );
    }

    let fileName = this.props.upload.file_name;
    if (fileName.length > 60) {
      const ellipsis = '…';
      fileName = this.props.upload.file_name.substr(0, 60) + ellipsis;
    }

    let imageFile;
    if (this.props.upload.deleted) {
      imageFile = '/assets/images/deleted_image.svg';
    } else {
      imageFile = this.props.upload.thumburl;
    }

    return (
      <tr className="upload">
        <td>
          <a href={this.props.upload.url} target="_blank">
            <img src={imageFile} />
          </a>
          {details}
        </td>
        <td className="desktop-only-tc">
          <a href={this.props.upload.url} target="_blank">{fileName}</a>
        </td>
        <td className="desktop-only-tc">{this.props.upload.uploader}</td>
        <td className="desktop-only-tc">{this.props.upload.usage_count}</td>
        <td className="desktop-only-tc">{moment(this.props.upload.uploaded_at).format('YYYY-MM-DD   h:mm A')}</td>
        <td></td>
      </tr>
    );
  }
}
);

export default Upload;
