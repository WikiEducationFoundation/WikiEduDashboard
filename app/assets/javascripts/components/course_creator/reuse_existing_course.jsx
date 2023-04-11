import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const ReuseExistingCourse = ({ selectClassName, courseSelect, useThisClassAction, options, stringPrefix, cancelCloneAction, assignmentsWithoutUsers, checkBoxLabel }) => { // eslint-disable-line no-unused-vars
  return (
    <div className={selectClassName}>
      <div>
        {courseSelect}
        <button className="button dark" onClick={useThisClassAction}>{CourseUtils.i18n('creator.clone_this', stringPrefix)}</button>
        <button className="button dark right" onClick={cancelCloneAction}>{CourseUtils.i18n('cancel', stringPrefix)}</button>
      </div>
      {assignmentsWithoutUsers && checkBoxLabel}
    </div>
  );
};

export default ReuseExistingCourse;
