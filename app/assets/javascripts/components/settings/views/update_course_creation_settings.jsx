import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import CourseCreationSettingsForm from '../containers/course_creation_settings_form_container.jsx';
import Popover from '../../common/popover.jsx';
import PopoverExpandable from '../../high_order/popover_expandable.jsx';

const UpdateCourseCreationSettings = createReactClass({
  propTypes: {
    open: PropTypes.func,
    is_open: PropTypes.bool,
    settings: PropTypes.object
  },

  getKey() {
    return 'update_course_creation_settings';
  },

  render() {
    const form = <CourseCreationSettingsForm handlePopoverClose={this.props.open} settings={this.props.settings} />;
    return (
      <div className="pop__container">
        <button className="button dark" onClick={this.props.open}>Update course creation settings</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={form}
          right
        />
      </div>
    );
  }
});

export default PopoverExpandable(UpdateCourseCreationSettings);
