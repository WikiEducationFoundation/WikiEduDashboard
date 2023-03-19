import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import EditableRedux from '../high_order/editable_redux.jsx';
import TextAreaInput from '../common/text_area_input.jsx';

const Description = createReactClass({
  displayName: 'Description',

  propTypes: {
    description: PropTypes.string,
    title: PropTypes.string,
    editable: PropTypes.bool,
    controls: PropTypes.any,
    updateCourse: PropTypes.func.isRequired, // used by EditableRedux
    resetState: PropTypes.func.isRequired, // used by EditableRedux
    persistCourse: PropTypes.func.isRequired // used by EditableRedux
  },

  updateDescription(_valueKey, value) {
    return this.props.updateCourse({ description: value });
  },

  render() {
    return (
      <div className="module course-description">
        <div className="section-header">
          <h3>{this.props.title.replaceAll('_', ' ')}</h3>
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

export default EditableRedux(Description, I18n.t('editable.edit_description'));
