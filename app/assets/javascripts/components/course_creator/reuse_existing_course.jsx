import React from 'react';
import CourseUtils from '../../utils/course_utils.js';

const ReuseExistingCourse = ({ selectClassName, courseSelect, useThisClassAction, options, stringPrefix, cancelCloneAction, assignmentsWithoutUsers, setCopyCourseAssignments, copyCourseAssignments, labelText }) => { // eslint-disable-line no-unused-vars
  const checkBoxLabel = (
    <span style={{ marginLeft: '1vh', marginRight: '3vh' }}>
      <input id="copy_cloned_articles" type="checkbox" checked={copyCourseAssignments} onChange={setCopyCourseAssignments}/>
      <label htmlFor="checkbox_id">{I18n.t('courses.creator.copy_courses_with_assignments')}</label>
    </span>
  );
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
