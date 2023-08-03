import PropTypes from 'prop-types';
import React from 'react';
import CourseCreationSettingsForm from '../containers/course_creation_settings_form_container.jsx';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const UpdateCourseCreationSettings = ({ settings }) => {
  const getKey = () => {
    return 'update_course_creation_settings';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <CourseCreationSettingsForm handlePopoverClose={open} settings={settings} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update course creation settings</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};
UpdateCourseCreationSettings.propTypes = {
  settings: PropTypes.object
};
export default UpdateCourseCreationSettings;
