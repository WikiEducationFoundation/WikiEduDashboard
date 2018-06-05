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
      limit: 100,
      data: [],
      selectedPage: 1,
      perPage: 100,
    };
  },

  componentWillMount() {
    this.props.receiveUploads(this.props.course_id, this.state.limit);
    this.setState({ data: this.props.uploads });
  },

  componentWillReceiveProps(nextProps) {
    const offset = (this.state.selectedPage - 1) * this.state.perPage;
    const uploads = nextProps.uploads.slice(offset, offset + 100);
    this.setState({ data: uploads });
  },

  handlePageClick(data) {
    const selectedPage = data.selected + 1;
    const limit = selectedPage * this.state.perPage;
    this.setState({ limit: limit, selectedPage: selectedPage }, () => {
      this.props.receiveUploads(this.props.course_id, this.state.limit);
    });
  },

  sortSelect(e) {
    return this.props.sortUploads(e.target.value);
  },

  render() {
    const pageCount = Math.ceil(this.props.count / 100);
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
        <UploadList uploads={this.state.data} />
        <ReactPaginate
          previousLabel={"← Previous"}
          nextLabel={"Next →"}
          breakLabel={<span className="gap">...</span>}
          pageCount={pageCount}
          marginPagesDisplayed={2}
          pageRangeDisplayed={6}
          forcepage={this.state.currentPage}
          onPageChange={this.handlePageClick}
          containerClassName={"pagination"}
          previousLinkClassName={"previous_page"}
          nextLinkClassName={"next_page"}
          disabledClassName={"disabled"}
          activeClassName={"active"}
        />
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  uploads: state.uploads.uploads,
  count: state.uploads.count
});

const mapDispatchToProps = {
  receiveUploads,
  sortUploads,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
