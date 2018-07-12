import React from 'react';
import { connect } from 'react-redux';
import ReactPaginate from 'react-paginate';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import UploadList from './upload_list.jsx';
import { receiveUploads, sortUploads, setView, setUploadFilters, setUploadMetadata } from '../../actions/uploads_actions.js';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import MultiSelectField from '../common/multi_select_field.jsx';
import { getStudentUsers, getFilteredUploads } from '../../selectors';

const UploadsHandler = createReactClass({
  displayName: 'UploadsHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object
  },

  getInitialState() {
    return {
      options: [],
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
    const options = nextProps.students.map(student => {
      return { label: student.username, value: student.username };
    });

    const data = nextProps.selectedUploads.slice(this.state.offset, this.state.offset + this.state.perPage);

    this.setState({
      data: data,
      pageCount: Math.ceil(nextProps.selectedUploads.length / this.state.perPage),
      options: options,
     });

     if (!nextProps.fetchState) {
       this.setUploadMetadata(data);
     }

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
    const data = this.props.selectedUploads.slice(offset, offset + this.state.perPage);
    this.setUploadMetadata(data);
    this.setState({ offset: offset, data: data, currentPage: selectedPage });
  },

  setView(view) {
    this.props.setView(view);
  },

  setUploadFilters(selectedFilters) {
    this.setState({ offset: 0, currentPage: 0 }, () => {
      this.props.setUploadFilters(selectedFilters);
    });
  },

  setUploadMetadata(uploads) {
    return this.props.setUploadMetadata(uploads);
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
            <button id="gallery-view" className="button border icon-gallery_view icon tooltip-trigger" onClick={() => {this.setView(GALLERY_VIEW);}}>
              <p className="tooltip dark">Gallery View</p>
            </button>
            <button id="list-view" className="button border icon-list_view icon tooltip-trigger" onClick={() => {this.setView(LIST_VIEW);}}>
              <p className="tooltip dark">List View</p>
            </button>
            <button id="tile-view" className="button border icon-tile_view icon tooltip-trigger" onClick={() => {this.setView(TILE_VIEW);}}>
              <p className="tooltip dark">Tile View</p>
            </button>
          </div>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
              <option value="uploader">{I18n.t('uploads.uploader')}</option>
              <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
            </select>
          </div>
        </div>
        <MultiSelectField options={this.state.options} label={I18n.t('uploads.select_label')} selected={this.props.selectedFilters} setSelectedFilters={this.setUploadFilters} />
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
  students: getStudentUsers(state),
  selectedFilters: state.uploads.selectedFilters,
  selectedUploads: getFilteredUploads(state),
  fetchState: state.uploads.fetchState,
});

const mapDispatchToProps = {
  receiveUploads,
  sortUploads,
  setView,
  setUploadFilters,
  setUploadMetadata,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
