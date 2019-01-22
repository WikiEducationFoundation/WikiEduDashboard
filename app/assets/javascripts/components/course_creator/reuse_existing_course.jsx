import React from 'react';

const ReuseExistingCourse = ({ selectClassName, courseSelect, useThisClassAction, options, cloneThisLabel, cancelCloneAction, cancelLabel }) => { // eslint-disable-line no-unused-vars
  return (
    <div className={selectClassName}>
      {courseSelect}
      <button className="button dark" onClick={useThisClassAction}>{cloneThisLabel}</button>
      <button className="button dark right" onClick={cancelCloneAction}>{cancelLabel}</button>
    </div>
  );
};

export default ReuseExistingCourse;
