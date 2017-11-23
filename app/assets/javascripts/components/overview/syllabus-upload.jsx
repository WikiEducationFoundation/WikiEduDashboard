import React from 'react';
import PropTypes from 'prop-types';
import Dropzone from 'react-dropzone';
import CourseActions from '../../actions/course_actions.js';
import Loading from '../common/loading.jsx';

export default class SyllabusUpload extends React.Component {
  constructor() {
    super();
    this.onDrop = this._onDrop.bind(this);
    this.toggleEditing = this._toggleEditing.bind(this);
    this.removeSyllabus = this._removeSyllabus.bind(this);
  }
  _onDrop(files) {
    CourseActions.startUploadSyllabus();
    CourseActions.uploadSyllabus({
      courseId: this.props.course.id,
      file: files[0]
    });
  }
  _uploader() {
    const { uploadingSyllabus } = this.props;
    const cancelButton = <button className="link-button" onClick={() => { this.toggleEditing(false); }}>cancel</button>;
    const loadingAnimation = <Loading message={false} />;
    const dropzone = (
      <Dropzone onDrop={this.onDrop} multiple={false} className="course-syllabus__uploader">
        <div>Drag and Drop or <button id="browse_files" className="link-button">Browse Files</button></div>
      </Dropzone>
    );
    return (
      <div>
        {(uploadingSyllabus ? loadingAnimation : dropzone)}
        {cancelButton}
      </div>
    );
  }
  _toggleEditing(bool) {
    CourseActions.toggleEditingSyllabus(bool);
  }
  _syllabusLink() {
    const { syllabus } = this.props.course;
    let link = <span>No syllabus has been added.</span>;
    if (syllabus !== undefined) {
      const filename = syllabus.split('/').pop().split('?')[0];
      link = <a href={syllabus}>{filename}</a>;
    }
    return link;
  }
  _removeSyllabus() {
    CourseActions.uploadSyllabus({
      courseId: this.props.course.id,
      file: null
    });
  }
  render() {
    const { syllabus, canUploadSyllabus, editingSyllabus } = this.props.course;
    const editButton = canUploadSyllabus ? <button className="link-button" onClick={() => { this.toggleEditing(true); }}>edit</button> : null;
    return (
      <div className="module course-description course__syllabus-upload__inner">
        <div className="module__data">
          <h3>Syllabus</h3>
          {this._syllabusLink()}
          &nbsp;
          &nbsp;
          {(canUploadSyllabus && editingSyllabus ? this._uploader() : editButton)}
          &nbsp;
          &nbsp;
          {(syllabus !== undefined ? <button className="link-button" onClick={this.removeSyllabus}>remove</button> : null)}
          &nbsp;
          &nbsp;
          <a className="link-button" href={`/courses/${this.props.course.slug}`}>save</a>
        </div>
      </div>
    );
  }
}

SyllabusUpload.propTypes = {
  course: PropTypes.object.isRequired,
  syllabus: PropTypes.string,
  editingSyllabus: PropTypes.bool,
  uploadingSyllabus: PropTypes.bool
};
