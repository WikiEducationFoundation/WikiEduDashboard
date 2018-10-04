import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import _ from 'lodash';
import moment from 'moment';
import OnClickOutside from 'react-onclickoutside';
import { connect } from 'react-redux';
import { setUploadViewerMetadata, setUploadPageViews } from '../../actions/uploads_actions.js';

const UploadViewer = createReactClass({
  displayName: 'UploadViewer',

  propTypes: {
    upload: PropTypes.object,
    closeUploadViewer: PropTypes.func,
  },

  getInitialState() {
    return {
      loadingViews: true,
      uploadViews: []
    };
  },

  componentWillMount() {
    this.props.setUploadViewerMetadata(this.props.upload);
  },

  componentWillReceiveProps(newProps) {
    if ((this.props.pageViews !== '') || (newProps.pageViews !== '') || (newProps.pageViews !== this.props.pageViews)) {
      this.setState({
        uploadViews: [...this.state.uploadViews, this.props.pageViews, newProps.pageViews]
      });
    }
  },

  componentDidUpdate() {
    const metadata = _.get(this.props.uploadMetadata, `query.pages[${this.props.upload.id}]`);
    const fileUsage = _.get(metadata, 'globalusage', []);
    if (fileUsage) {
      const createdAt = _.get(metadata, 'imageinfo[0].extmetadata.DateTime.value');
      if (this.state.loadingViews) {
        this.handleGetFileViews(fileUsage, createdAt);
      }
    }
  },

  handleGetFileViews(files, createdAt) {
    if (createdAt !== undefined) {
      const createdDate = createdAt.split(' ');
      this.props.setUploadPageViews(files, createdDate[0]);
    }
    this.setState({
      loadingViews: false
    });
  },

  handleClickOutside() {
    this.props.closeUploadViewer();
  },


  render() {
    const metadata = _.get(this.props.uploadMetadata, `query.pages[${this.props.upload.id}]`);
    const imageDescription = _.get(metadata, 'imageinfo[0].extmetadata.ImageDescription.value');
    const width = _.get(metadata, 'imageinfo[0].width');
    const height = _.get(metadata, 'imageinfo[0].height');

    let size = _.get(metadata, 'imageinfo[0].size');
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(size) / Math.log(1024));
    size = `${parseFloat((size / (1024 ** i)).toFixed(2))} ${sizes[i]}`;

    const imageUrl = _.get(metadata, 'imageinfo[0].url');

    const profileLink = `/users/${encodeURIComponent(this.props.upload.uploader)}`;
    const author = <a href={profileLink} target="_blank">{this.props.upload.uploader}</a>;
    const source = _.get(metadata, 'imageinfo[0].extmetadata.Credit.value');
    const license = _.get(metadata, 'imageinfo[0].extmetadata.LicenseShortName.value');

    const eyeIcon = <span><img className="eye-icon" src="/assets/images/icon-eye.png" alt="View icon" /></span>;

    const globalUsage = _.get(metadata, 'globalusage', []);
    let usageTableElements;
    if (globalUsage) {
      usageTableElements = globalUsage.map((usage, key) => {
        return this.state.uploadViews.slice(0).reverse()
          .filter((value, j) => { if (j % 2 === 0) { return value; } return null; })
          .map((views, index) => {
            if ((key === index)) {
              return (
                <tr>
                  <td>{usage.wiki}</td>
                  <td><a href={usage.url}>{usage.title}</a></td>
                  <td>{views}</td>
                </tr>
              );
            }
            return null;
          });
      });
    }

    let fileUsageTable;
    if (globalUsage.length > 0) {
      fileUsageTable = (
        <div>
          <h4>File usage on other wikis</h4>
          <table>
            <thead>
              <tr>
                <th>Wiki</th>
                <th>Article Name</th>
                <th>{eyeIcon}</th>
              </tr>
            </thead>
            <tbody>
              {usageTableElements}
            </tbody>
          </table>
        </div>
      );
    }
    let categoriesList = '';
    let categories;
    _.forEach(_.get(metadata, 'categories', []), category => categoriesList = `${categoriesList} | ${category.title}`);
    if (categoriesList.length > 0) {
      categoriesList = categoriesList.slice(2);
      categories = (
        <div>
          <h4>Categories</h4>
          {categoriesList}
        </div>
      );
    }

    return (
      <div className="module upload-viewer">
        <div className="modal-header">
          <button className="pull-right icon-close" onClick={this.props.closeUploadViewer} />
          <h3>{this.props.upload.file_name}</h3>
        </div>
        <div className="modal-body">
          <div className="left">
            <a href={this.props.upload.url} target="_blank"><img alt={this.props.upload.file_name} src={this.props.imageFile} /></a>
            <p><a href={imageUrl} target="_blank">Original File</a>{` (${width} X ${height} pixels, file size: ${size})`}</p>
            <h4>Description</h4>
            <p dangerouslySetInnerHTML={{ __html: imageDescription }} />
          </div>
          <div className="right">
            <table>
              <tbody>
                <tr>
                  <td className="bg-grey">Date</td>
                  <td>{moment(this.props.upload.uploaded_at).format('YYYY-MM-DD')}</td>
                </tr>
                <tr>
                  <td className="bg-grey">Author</td>
                  <td>{author}</td>
                </tr>
                <tr>
                  <td className="bg-grey">Source</td>
                  <td dangerouslySetInnerHTML={{ __html: source }} />
                </tr>
                <tr>
                  <td className="bg-grey">License</td>
                  <td>{license}</td>
                </tr>
              </tbody>
            </table>
            {categories}
            {fileUsageTable}
          </div>
        </div>
        <div className="modal-footer">
          <a className="button dark small pull-right upload-viewer-button" href={this.props.upload.url} target="_blank">View on Commons</a>
        </div>
      </div>
    );
  }
});

const mapStateToProps = state => ({
  uploadMetadata: state.uploads.uploadMetadata,
  pageViews: state.uploads.pageViews
});

const mapDispatchToProps = {
  setUploadViewerMetadata,
  setUploadPageViews
};

export default connect(mapStateToProps, mapDispatchToProps)(OnClickOutside(UploadViewer));
