import React from 'react';
import { connect } from 'react-redux';
import ReactPaginate from 'react-paginate';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import UploadList from './upload_list.jsx';
import { receiveUploads, sortUploads, setView } from '../../actions/uploads_actions.js';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';

const UploadsHandler = createReactClass({
  displayName: 'UploadsHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object
  },

  getInitialState() {
    return {
      offset: 0,
      data: [],
      perPage: 100,
      currentPage: 0,
    };
  },

  componentWillMount() {
    return this.props.receiveUploads(this.props.course_id);
  },

  componentWillReceiveProps(nextProps) {
    const data = nextProps.uploads.slice(this.state.offset, this.state.offset + this.state.perPage);
    this.setState({ data: data, pageCount: Math.ceil(nextProps.uploads.length / this.state.perPage) });
    if (nextProps.view === LIST_VIEW) {
      document.getElementById("list-view").classList.add("dark");
      document.getElementById("gallery-view").classList.remove("dark");
      document.getElementById("tile-view").classList.remove("dark");
    }
    else if (nextProps.view === GALLERY_VIEW) {
      document.getElementById("gallery-view").classList.add("dark");
      document.getElementById("list-view").classList.remove("dark");
      document.getElementById("tile-view").classList.remove("dark");
    }
    else {
      document.getElementById("gallery-view").classList.remove("dark");
      document.getElementById("list-view").classList.remove("dark");
      document.getElementById("tile-view").classList.add("dark");
    }
  },

  setUploadData(offset, selectedPage) {
    const data = this.props.uploads.slice(offset, offset + this.state.perPage);
    this.setState({ offset: offset, data: data, currentPage: selectedPage });
  },

  setView(view) {
    this.props.setView(view);
  },

  handlePageClick(data) {
    const selectedPage = data.selected;
    const offset = Math.ceil(selectedPage * this.state.perPage);
    this.setUploadData(offset, selectedPage);
  },

  sortSelect(e) {
    return this.props.sortUploads(e.target.value);
  },

  render() {
    let paginationElement;
    if (this.state.pageCount > 1) {
      paginationElement = (
        <ReactPaginate
          previousLabel={"← Previous"}
          nextLabel={"Next →"}
          breakLabel={<span className="gap">...</span>}
          pageCount={this.state.pageCount}
          marginPagesDisplayed={2}
          pageRangeDisplayed={6}
          onPageChange={this.handlePageClick}
          forcePage={this.state.currentPage}
          containerClassName={"pagination"}
          previousLinkClassName={"previous_page"}
          nextLinkClassName={"next_page"}
          disabledClassName={"disabled"}
          activeClassName={"active"}
        />
      );
    }

    return (
      <div id="uploads">
        <div className="section-header">
          <h3>{I18n.t('uploads.header')}</h3>
          <div className="view-buttons">
            <button id="list-view" className="button border icon-list_view icon tooltip-trigger" onClick={() => {this.setView(LIST_VIEW);}}>
              <p className="tooltip dark">List View</p>
            </button>
            <button id="gallery-view" className="button border icon-gallery_view icon tooltip-trigger" onClick={() => {this.setView(GALLERY_VIEW);}}>
              <p className="tooltip dark">Gallery View</p>
            </button>
            <button id="tile-view" className="button border icon-tile_view icon tooltip-trigger" onClick={() => {this.setView(TILE_VIEW);}}>
              <p className="tooltip dark">Tile View</p>
            </button>
          </div>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
              <option value="uploader">{I18n.t('uploads.uploaded_by')}</option>
              <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
            </select>
          </div>
        </div>
        {paginationElement}
        <UploadList uploads={this.state.data} view={this.props.view} sortBy={this.props.sortUploads} />
        {paginationElement}
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  uploads: state.uploads.uploads,
  view: state.uploads.view,
});

const mapDispatchToProps = {
  receiveUploads: receiveUploads,
  sortUploads: sortUploads,
  setView: setView,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
