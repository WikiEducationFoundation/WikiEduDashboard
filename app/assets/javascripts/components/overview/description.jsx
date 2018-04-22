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
    description: PropTypes.string,
    title: PropTypes.string,
    editable: PropTypes.bool,
    controls: PropTypes.any
  },

  updateDescription(_valueKey, value) {
    return CourseActions.updateCourse({ description: value });
  },

  render() {
    return (
      <div className="module course-description">
        <div className="section-header">
          <h3>{this.props.title}</h3>
          {this.props.controls()}
        </div>
        <div className="module__data">
          <TextAreaInput
            onChange={this.updateDescription}
            value={this.props.description}
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
