import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import ReactPaginate from 'react-paginate';
import PropTypes from 'prop-types';
import UploadList from './upload_list.jsx';
import { receiveUploads, sortUploads, setView, setUploadFilters, setUploadMetadata } from '../../actions/uploads_actions.js';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import MultiSelectField from '../common/multi_select_field.jsx';
import { getStudentUsers, getFilteredUploads } from '../../selectors';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select.js';

const UPLOADS_PER_PAGE = 100;

const UploadsHandler = ({ course_id, course }) => {
  const [offset, setOffset] = useState(0);
  const [currentPage, setCurrentPage] = useState(0);

  const stateValues = useSelector(state => ({
    selectedUploads: getFilteredUploads(state),
    loadingUploads: state.uploads.loading,
    view: state.uploads.view,
    students: getStudentUsers(state),
    selectedFilters: state.uploads.selectedFilters,
    totalUploadsCount: state.uploads.uploads.length
  }));

  const dispatch = useDispatch();

  useEffect(() => {
    document.title = `${course.title} - ${I18n.t('uploads.label')}`;
    if (stateValues.loadingUploads) {
      dispatch(receiveUploads(course_id));
    }
  }, [course.title, course_id, stateValues.loadingUploads]);

  useEffect(() => {
    const data = stateValues.selectedUploads.slice(offset, offset + UPLOADS_PER_PAGE);
    if (currentPage === 0) {
      setUploadMetadataHandler(data);
    }
    setOffset(0);
    setCurrentPage(0);
  }, [stateValues.selectedUploads, currentPage]);

  const setUploadMetadataHandler = (uploads) => {
    dispatch(setUploadMetadata(uploads));
  };

  const handlePageClick = (data) => {
    const selectedPage = data.selected;
    const newOffset = Math.ceil(selectedPage * UPLOADS_PER_PAGE);
    const newData = stateValues.selectedUploads.slice(newOffset, newOffset + UPLOADS_PER_PAGE);
    setUploadMetadataHandler(newData);
    setOffset(newOffset);
    setCurrentPage(selectedPage);
  };

  const sortSelect = (e) => {
    dispatch(sortUploads(e.value));
  };

  const setUploadFiltersHandler = (newSelectedFilters) => {
    setOffset(0);
    setCurrentPage(0);
    dispatch(setUploadFilters(newSelectedFilters));
  };

  const setViewHandler = (newView) => {
    dispatch(setView(newView));
  };

  const options = stateValues.students.map(student => ({
    label: student.username,
    value: student.username
  }));

  let galleryClass = 'button border icon-gallery_view icon tooltip-trigger';
  let listClass = 'button border icon-list_view icon tooltip-trigger';
  let tileClass = 'button border icon-tile_view icon tooltip-trigger';
  if (stateValues.view === GALLERY_VIEW) {
    galleryClass += ' dark';
  } else if (stateValues.view === LIST_VIEW) {
    listClass += ' dark';
  } else if (stateValues.view === TILE_VIEW) {
    tileClass += ' dark';
  }

  let paginationElement;
  const pageCount = Math.ceil(stateValues.selectedUploads.length / UPLOADS_PER_PAGE);
  if (pageCount > 1) {
    paginationElement = (
      <ReactPaginate
        previousLabel={'← Previous'}
        nextLabel={'Next →'}
        breakLabel={<span className="gap">...</span>}
        pageCount={pageCount}
        marginPagesDisplayed={2}
        pageRangeDisplayed={6}
        onPageChange={handlePageClick}
        forcePage={currentPage}
        containerClassName={'pagination'}
        previousLinkClassName={'previous_page'}
        nextLinkClassName={'next_page'}
        disabledClassName={'disabled'}
        className={({ isActive }) => (isActive ? 'active' : '')}
      />
    );
  }

  const sortOptions = [
    { value: 'uploaded_at', label: I18n.t('uploads.uploaded_at') },
    { value: 'uploader', label: I18n.t('uploads.uploader') },
    { value: 'usage_count', label: I18n.t('uploads.usage_count') },
  ];

  return (
    <div id="uploads">
      <div className="section-header">
        <h3>{I18n.t('uploads.header')}</h3>
        <div className="view-buttons">
          <button id="gallery-view" className={galleryClass} onClick={() => { setViewHandler(GALLERY_VIEW); }}>
            <p className="tooltip dark">{I18n.t('uploads.gallery_view')}</p>
          </button>
          <button id="list-view" className={listClass} onClick={() => { setViewHandler(LIST_VIEW); }}>
            <p className="tooltip dark">{I18n.t('uploads.list_view')}</p>
          </button>
          <button id="tile-view" className={tileClass} onClick={() => { setViewHandler(TILE_VIEW); }}>
            <p className="tooltip dark">{I18n.t('uploads.tile_view')}</p>
          </button>
        </div>
        <div className="sort-container">
          <Select
            name="sorts"
            onChange={sortSelect}
            options={sortOptions}
            styles={sortSelectStyles}
          />
        </div>
      </div>
      <MultiSelectField options={options} label={I18n.t('uploads.select_label')} selected={stateValues.selectedFilters} setSelectedFilters={setUploadFiltersHandler} />
      {paginationElement}
      <UploadList uploads={stateValues.selectedUploads.slice(offset, offset + UPLOADS_PER_PAGE)} view={stateValues.view} sortBy={sortSelect} loadingUploads={stateValues.loadingUploads} totalUploadsCount={stateValues.totalUploadsCount} />
      {paginationElement}
    </div>
  );
};

UploadsHandler.propTypes = {
  course_id: PropTypes.string,
  course: PropTypes.object
};

export default UploadsHandler;
