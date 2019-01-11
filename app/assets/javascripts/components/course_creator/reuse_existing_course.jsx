import React from 'react';

const ReuseExistingCourse = ({ selectClassName, chooseNewCourseAction, useThisClassAction, options, cloneThisLabel, cancelCloneAction, cancelLabel }) => {
  return (
    <div className={selectClassName}>
      <select id="reuse-existing-course-select" ref={(dropdown) => { chooseNewCourseAction = dropdown; }}>{options}</select>
      <button className="button dark" onClick={useThisClassAction}>{cloneThisLabel}</button>
      <button className="button dark right" onClick={cancelCloneAction}>{cancelLabel}</button>
    </div>
  );
};

export default ReuseExistingCourse;
