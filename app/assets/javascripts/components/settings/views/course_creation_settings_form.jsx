import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import TextInput from '../../common/text_input';

const CourseCreationSettingsForm = createReactClass({
  propTypes: {
    updateCourseCreationSettings: PropTypes.func,
    handlePopoverClose: PropTypes.func,
    settings: PropTypes.object
  },

  getInitialState() {
    return {};
  },

  handleChange(key, value) {
    return this.setState({ [key]: value });
  },

  handleSubmit(e) {
    e.preventDefault();
    this.props.updateCourseCreationSettings(this.state);
    this.props.handlePopoverClose(e);
  },

  render() {
    return (
      <tr>
        <td>
          <form onSubmit={this.handleSubmit}>
            <TextInput
              id="recruiting_term"
              editable
              onChange={this.handleChange}
              value={this.state.recruiting_term}
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
              onChange={this.handleChange}
              value={this.state.before_deadline_message}
              value_key="before_deadline_message"
              maxLength="1000"
              type="text"
              label="Message before deadline"
            />
            <TextInput
              id="after_deadline_message"
              editable
              onChange={this.handleChange}
              value={this.state.after_deadline_message}
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
  }
});

export default CourseCreationSettingsForm;
