import React from 'react';
import PropTypes from 'prop-types';
import EditableRedux from '../high_order/editable_redux.jsx';
import TextAreaInput from '../common/text_area_input.jsx';

const Description = ({ updateCourse, title, controls, description, editable }) => {
  const updateDescription = (_valueKey, value) => {
    return updateCourse({ description: value });
  };

  return (
    <div className="module course-description" >
      <div className="section-header">
        <h3>{title}</h3>
        {controls()}
      </div>
      <div className="module__data">
        <TextAreaInput
          onChange={updateDescription}
          value={description}
          placeholder={I18n.t('courses.creator.course_description')}
          value_key={'description'}
          editable={editable}
          markdown={true}
          autoExpand={true}
        />
      </div>
    </div >
  );
};

Description.propTypes = {
  description: PropTypes.string,
  title: PropTypes.string,
  editable: PropTypes.bool,
  controls: PropTypes.any,
  updateCourse: PropTypes.func.isRequired, // used by EditableRedux
  resetState: PropTypes.func.isRequired, // used by EditableRedux
  persistCourse: PropTypes.func.isRequired // used by EditableRedux
};

export default EditableRedux(Description, I18n.t('editable.edit_description'));
