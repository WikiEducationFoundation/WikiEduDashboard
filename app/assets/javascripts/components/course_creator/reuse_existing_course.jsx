import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const ReuseExistingCourse = ({ selectClassName, courseSelect, useThisClassAction, options, stringPrefix, cancelCloneAction, assignmentsWithoutUsers, setCopyCourseAssignments, copyCourseAssignments, labelText }) => { // eslint-disable-line no-unused-vars
  const checkBoxLabel = (
    <span style={{ marginLeft: '1vh', marginRight: '3vh' }}>
      <input type="checkbox" name="checkbox" id="checkbox_id" checked={copyCourseAssignments} onChange={setCopyCourseAssignments}/>
      <label htmlFor="checkbox_id">{labelText}</label>
    </span>
  );
  return (
    <div className={selectClassName}>
      <div className="select-checkbox-wrapper">
        <div className="select-checkbox">
          {courseSelect}
          {assignmentsWithoutUsers && checkBoxLabel}
        </div>
        <button className="button dark" onClick={useThisClassAction}>{CourseUtils.i18n('creator.clone_this', stringPrefix)}</button>
      </div>
      <button className="button dark right" onClick={cancelCloneAction}>{CourseUtils.i18n('cancel', stringPrefix)}</button>
    </div>
  );
};

export default ReuseExistingCourse;
