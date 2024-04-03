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

const UPLOADS_PER_PAGE = 100;

const UploadsHandler = createReactClass({
  displayName: 'UploadsHandler',
  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object
  },

  getInitialState() {
    return {
      offset: 0,
      data: this.props.selectedUploads.slice(0, UPLOADS_PER_PAGE),
      currentPage: 0,
      pageCount: Math.ceil(this.props.selectedUploads.length / UPLOADS_PER_PAGE),
    };
  },

  componentDidMount() {
    document.title = `${this.props.course.title} - ${I18n.t('uploads.label')}`;
    if (this.props.loadingUploads) {
      return this.props.receiveUploads(this.props.course_id);
    }
  },

  componentDidUpdate(prevProps) {
    if (this.props !== prevProps) {
      const data = this.props.selectedUploads.slice(this.state.offset, this.state.offset + UPLOADS_PER_PAGE);
      if (this.state.currentPage === 0) {
        this.setUploadMetadata(data);
      }
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({
      data: data,
      pageCount: Math.ceil(this.props.selectedUploads.length / UPLOADS_PER_PAGE),
      });
    }
  },

  setUploadData(offset, selectedPage) {
    const data = this.props.selectedUploads.slice(offset, offset + UPLOADS_PER_PAGE);
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
    const offset = Math.ceil(selectedPage * UPLOADS_PER_PAGE);
    this.setUploadData(offset, selectedPage);
  },

  sortSelect(e) {
    return this.props.sortUploads(e.target.value);
  },

  render() {
    const options = this.props.students.map((student) => {
      return { label: student.username, value: student.username };
    });

    let galleryClass = 'button border icon-gallery_view icon tooltip-trigger';
    let listClass = 'button border icon-list_view icon tooltip-trigger';
    let tileClass = 'button border icon-tile_view icon tooltip-trigger';
    if (this.props.view === GALLERY_VIEW) {
      galleryClass += ' dark';
    } else if (this.props.view === LIST_VIEW) {
      listClass += ' dark';
    } else if (this.props.view === TILE_VIEW) {
      tileClass += ' dark';
    }

    let paginationElement;
    if (this.state.pageCount > 1) {
      paginationElement = (
        <ReactPaginate
          previousLabel={'← Previous'}
          nextLabel={'Next →'}
          breakLabel={<span className="gap">...</span>}
          pageCount={this.state.pageCount}
          marginPagesDisplayed={2}
          pageRangeDisplayed={6}
          onPageChange={this.handlePageClick}
          forcePage={this.state.currentPage}
          containerClassName={'pagination'}
          previousLinkClassName={'previous_page'}
          nextLinkClassName={'next_page'}
          disabledClassName={'disabled'}
          className={({ isActive }) => (isActive ? 'active' : '')}
        />
      );
    }

    return (
      <div id="uploads">
        <div className="section-header">
          <h3>{I18n.t('uploads.header')}</h3>
          <div className="view-buttons">
            <button id="gallery-view" className={galleryClass} onClick={() => { this.setView(GALLERY_VIEW); }}>
              <p className="tooltip dark">{I18n.t('uploads.gallery_view')}</p>
            </button>
            <button id="list-view" className={listClass} onClick={() => { this.setView(LIST_VIEW); }}>
              <p className="tooltip dark">{I18n.t('uploads.list_view')}</p>
            </button>
            <button id="tile-view" className={tileClass} onClick={() => { this.setView(TILE_VIEW); }}>
              <p className="tooltip dark">{I18n.t('uploads.tile_view')}</p>
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
        <MultiSelectField options={options} label={I18n.t('uploads.select_label')} selected={this.props.selectedFilters} setSelectedFilters={this.setUploadFilters} />
        {paginationElement}
        <UploadList uploads={this.state.data} view={this.props.view} sortBy={this.props.sortUploads} loadingUploads={this.props.loadingUploads} totalUploadsCount={this.props.uploads.length} />
        {paginationElement}
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  uploads: state.uploads.uploads,
  loadingUploads: state.uploads.loading,
  view: state.uploads.view,
  students: getStudentUsers(state),
  selectedFilters: state.uploads.selectedFilters,
  selectedUploads: getFilteredUploads(state),
});

const mapDispatchToProps = {
  receiveUploads,
  sortUploads,
  setView,
  setUploadFilters,
  setUploadMetadata,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
