import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const ReuseExistingCourse = ({ selectClassName, courseSelect, useThisClassAction, options, stringPrefix, cancelCloneAction }) => { // eslint-disable-line no-unused-vars
  return (
    <div className={selectClassName}>
      {courseSelect}
      <button className="button dark" onClick={useThisClassAction}>{CourseUtils.i18n('creator.clone_this', stringPrefix)}</button>
      <button className="button dark right" onClick={cancelCloneAction}>{CourseUtils.i18n('cancel', stringPrefix)}</button>
    </div>
  );
};

export default ReuseExistingCourse;
