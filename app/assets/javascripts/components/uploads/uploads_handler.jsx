import React from 'react';
import { connect } from 'react-redux';
import ReactPaginate from 'react-paginate';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import UploadList from './upload_list.jsx';
import { receiveUploads, sortUploads } from '../../actions/uploads_actions.js';

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
  },

  setUploadData(offset, selectedPage) {
    const data = this.props.uploads.slice(offset, offset + this.state.perPage);
    this.setState({ offset: offset, data: data, currentPage: selectedPage });
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
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
              <option value="uploader">{I18n.t('uploads.uploaded_by')}</option>
              <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
            </select>
          </div>
        </div>
        {paginationElement}
        <UploadList uploads={this.state.data} />
        {paginationElement}
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  uploads: state.uploads.uploads,
});

const mapDispatchToProps = {
  receiveUploads,
  sortUploads,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
