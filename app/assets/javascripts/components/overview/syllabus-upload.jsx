import React, { PropTypes } from 'react';
import Dropzone from 'react-dropzone';
import CourseActions from '../../actions/course_actions.js';

export default class SyllabusUpload extends React.Component {
  constructor() {
    super();
    this.onDrop = this._onDrop.bind(this);
  }
  _onDrop(files) {
    console.log(files, files);
    CourseActions.uploadFile({
      courseId: this.props.course.id,
      file: files[0]
    });
  }
  render() {
    console.log('syllabus props', this.props);
    return (
      <div>
        <Dropzone onDrop={this.onDrop} multiple={false}>
          <div>Drop your syllabus here</div>
        </Dropzone>
      </div>
    );
  }
}

SyllabusUpload.propTypes = {
  course: PropTypes.object.isRequired
};
