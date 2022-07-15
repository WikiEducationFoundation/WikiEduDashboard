import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { forEach, get } from 'lodash-es';
import moment from 'moment';
import OnClickOutside from 'react-onclickoutside';
import { connect } from 'react-redux';
import { setUploadViewerMetadata, setUploadPageViews, resetUploadsViews } from '../../actions/uploads_actions.js';

const UploadViewer = createReactClass({
  displayName: 'UploadViewer',

  propTypes: {
    upload: PropTypes.object,
    closeUploadViewer: PropTypes.func,
  },

  getInitialState() {
    return {
      loadingViews: true
    };
  },

  componentDidMount() {
    this.props.setUploadViewerMetadata(this.props.upload);
  },

  componentDidUpdate() {
    const metadata = get(this.props.uploadMetadata, `query.pages[${this.props.upload.id}]`);
    const fileUsage = get(metadata, 'globalusage', []);
    if (fileUsage) {
      if (this.state.loadingViews) {
        this.handleGetFileViews(fileUsage);
      }
    }
  },

  componentWillUnmount() {
    this.props.resetUploadsViews();
  },

  handleGetFileViews(files) {
    this.props.setUploadPageViews(files);
    this.setState({
      loadingViews: false
    });
  },

  handleClickOutside() {
    this.props.closeUploadViewer();
  },


  render() {
    const metadata = get(this.props.uploadMetadata, `query.pages[${this.props.upload.id}]`);
    const imageDescription = get(metadata, 'imageinfo[0].extmetadata.ImageDescription.value');
    const width = get(metadata, 'imageinfo[0].width');
    const height = get(metadata, 'imageinfo[0].height');

    let size = get(metadata, 'imageinfo[0].size');
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(size) / Math.log(1024));
    size = `${parseFloat((size / (1024 ** i)).toFixed(2))} ${sizes[i]}`;

    const imageUrl = get(metadata, 'imageinfo[0].url');

    const profileLink = `/users/${encodeURIComponent(this.props.upload.uploader)}`;
    const author = <a href={profileLink} target="_blank">{this.props.upload.uploader}</a>;
    const source = get(metadata, 'imageinfo[0].extmetadata.Credit.value');
    const license = get(metadata, 'imageinfo[0].extmetadata.LicenseShortName.value');
    const globalUsage = get(metadata, 'globalusage', []);
    let usageTableElements;
    if (globalUsage && (this.props.pageViews !== undefined)) {
      usageTableElements = globalUsage.map((usage, index) => {
          return (
            <tr className="view-file-details" key={usage.url}>
              <td className="row-details">{usage.wiki}&nbsp;&nbsp;&nbsp;</td>
              <td className="row-details"><a href={usage.url}>{usage.title}</a>&nbsp;&nbsp;&nbsp;</td>
              <td className="text-right row-details">{this.props.pageViews[index]}</td>
            </tr>
          );
      });
    }

    let fileUsageTable;
    if (globalUsage.length > 0) {
      fileUsageTable = (
        <div>
          <h1>{'\n'}</h1>
          <h4>File usage on other wikis</h4>
          <table border="1">
            <thead>
              <tr>
                <th>Wiki</th>
                <th>Article Name</th>
                <th>Views per day</th>
              </tr>
            </thead>
            <tbody>
              {usageTableElements}
            </tbody>
          </table>
        </div>
      );
    }
    let categoriesList = [];
    let categories;
    forEach(get(metadata, 'categories', []), (category) => {
      categoriesList.push(<span key={`span-${category.title}`}> | </span>);
      categoriesList.push(<a href={`https://commons.wikimedia.org/wiki/${category.title}`} target="_blank" key={`link-${category.title}`}>{category.title.slice('Category:'.length)}</a>);
    });
    if (categoriesList.length > 0) {
      categoriesList = categoriesList.splice(1);
      categories = (
        <div>
          <h1>{'\n'}</h1>
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
            <table className="view-file-details">
              <tbody>
                <tr>
                  <td className="row-details bg-grey">Date:&nbsp;</td>
                  <td className="row-details">{moment(this.props.upload.uploaded_at).format('YYYY-MM-DD')}</td>
                </tr>
                <tr>
                  <td className="row-details bg-grey">Author:&nbsp;</td>
                  <td className="row-details">{author}</td>
                </tr>
                <tr>
                  <td className="row-details bg-grey">Source:&nbsp;</td>
                  <td className="row-details" dangerouslySetInnerHTML={{ __html: source }} />
                </tr>
                <tr>
                  <td className="row-details bg-grey">License:&nbsp;</td>
                  <td className="row-details">{license}</td>
                  <td>{'\n'}</td>
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
  pageViews: state.uploads.averageViews
});

const mapDispatchToProps = {
  setUploadViewerMetadata,
  setUploadPageViews,
  resetUploadsViews
};

export default connect(mapStateToProps, mapDispatchToProps)(OnClickOutside(UploadViewer));
