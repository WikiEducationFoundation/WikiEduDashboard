import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Editable from '../high_order/editable.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import CourseStore from '../../stores/course_store.js';
import CourseActions from '../../actions/course_actions.js';

const getState = () => ({ course: CourseStore.getCourse() });

const Description = createReactClass({
  displayName: 'Description',

  propTypes: {
    course: PropTypes.object,
    editable: PropTypes.bool,
    controls: PropTypes.any
  },

  updateDescription(valueKey, value) {
    const toPass = this.props.course;
    toPass[valueKey] = value;
    return CourseActions.updateCourse(toPass);
  },

  render() {
    return (
      <div className="module course-description">
        <div className="section-header">
          <h3>{this.props.course.title}</h3>
          {this.props.controls()}
        </div>
        <div className="module__data">
          <TextAreaInput
            onChange={this.updateDescription}
            value={this.props.course.description}
            placeholder={I18n.t('courses.creator.course_description')}
            value_key={'description'}
            editable={this.props.editable}
            markdown={true}
            autoExpand={true}
          />
        </div>
      </div>
    );
  }
}
);

export default Editable(Description, [CourseStore], CourseActions.persistCourse, getState, I18n.t('editable.edit_description'));
