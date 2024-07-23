import React, { useState, useCallback } from 'react';
import PropTypes from 'prop-types';
import TextInput from '../../common/text_input';

const CourseCreationSettingsForm = ({ updateCourseCreationSettings, handlePopoverClose
 }) => {
  const [formState, setFormState] = useState({});

  const handleChange = useCallback((key, value) => {
    setFormState(prevState => ({
      ...prevState,
      [key]: value
    }));
  }, []);

  const handleSubmit = useCallback((e) => {
    e.preventDefault();
    updateCourseCreationSettings(formState);
    handlePopoverClose(e);
  }, [formState, updateCourseCreationSettings, handlePopoverClose]);

    return (
      <tr>
        <td>
          <form onSubmit={handleSubmit}>
            <TextInput
              id="recruiting_term"
              editable
              onChange={handleChange}
              value={formState.recruiting_term}
              value_key="recruiting_term"
              type="text"
              label="Recruiting term"
            />
            <TextInput
              id="deadline"
              editable
              onChange={this.handleChange}
              value={this.state.deadline}
              value_key="deadline"
              type="date"
              label="Deadline"
            />
            <TextInput
              id="before_deadline_message"
              editable
              onChange={handleChange}
              value={formState.before_deadline_message}
              value_key="before_deadline_message"
              maxLength="1000"
              type="text"
              label="Message before deadline"
            />
            <TextInput
              id="after_deadline_message"
              editable
              onChange={handleChange}
              value={formState.after_deadline_message}
              value_key="after_deadline_message"
              maxLength="1000"
              type="text"
              label="Message after deadline"
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    );
  };

  CourseCreationSettingsForm.propTypes = {
    updateCourseCreationSettings: PropTypes.func.isRequired,
    handlePopoverClose: PropTypes.func.isRequired,
    settings: PropTypes.object.isRequired
  };

export default CourseCreationSettingsForm;
