import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Dropzone from 'react-dropzone';
import Loading from '../common/loading.jsx';
import { toggleEditingSyllabus, uploadSyllabus } from '../../actions/course_actions';

const SyllabusUpload = ({ course }) => {
  const [isUploadingSyllabus, setIsUploadingSyllabus] = useState(false);
  const dispatch = useDispatch();

  const onDrop = (files) => {
    setIsUploadingSyllabus(true);
    dispatch(uploadSyllabus({
      courseId: course.id,
      file: files[0]
    })).then(() => setIsUploadingSyllabus(false));
  };

  const Uploader = () => {
    const cancelButton = <button className="link-button" onClick={() => dispatch(toggleEditingSyllabus())}>cancel</button>;
    const loadingAnimation = <Loading message={false} />;
    const dropzone = (
      <Dropzone onDrop={onDrop} multiple={false}>
        {({ getRootProps, getInputProps }) => (
          <div {...getRootProps()} className="course-syllabus__uploader">
            <input {...getInputProps()} />
            <div>
              Drag and Drop or <button id="browse_files" className="link-button">Browse Files</button>
            </div>
          </div>
        )}
      </Dropzone>
    );
    return (
      <div>
        {(isUploadingSyllabus ? loadingAnimation : dropzone)}
        {cancelButton}
      </div>
    );
  };

  const SyllabusLink = () => {
    const { syllabus } = course;
    let link = <span>No syllabus has been added.</span>;
    if (syllabus !== undefined) {
      const filename = syllabus.split('/').pop().split('?')[0];
      link = <a href={syllabus}>{filename}</a>;
    }
    return link;
  };
  const removeSyllabus = () => {
    dispatch(uploadSyllabus({
      courseId: course.id,
      file: null
    }));
  };
  const { syllabus, canUploadSyllabus, editingSyllabus } = course;
  const editButton = canUploadSyllabus ? <button className="link-button" onClick={() => dispatch(toggleEditingSyllabus())}>edit</button> : null;
  return (
    <div className="module course-description course__syllabus-upload__inner">
      <div className="module__data">
        <h3>Syllabus</h3>
        <SyllabusLink />
        {' '}
        {(canUploadSyllabus && editingSyllabus ? <Uploader /> : editButton)}
        {' '}
        {(syllabus !== undefined ? <button className="link-button" onClick={removeSyllabus}>remove</button> : null)}
        {' '}
        <a className="link-button" href={`/courses/${course.slug}`}>save</a>
      </div>
    </div>
  );
};

SyllabusUpload.propTypes = {
  course: PropTypes.object.isRequired,
};

export default (SyllabusUpload);
