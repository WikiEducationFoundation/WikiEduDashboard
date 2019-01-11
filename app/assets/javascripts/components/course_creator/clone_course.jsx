import React from 'react';

const CloneCourse = ({ cloneClasss, chooseNewCourseAction, showCloneChooserAction, createLabel, cloneLabel }) => {
  return (
    <div className={cloneClasss}>
      <button className="button dark" onClick={chooseNewCourseAction}>{createLabel}</button>
      <button className="button dark" onClick={showCloneChooserAction}>{cloneLabel}</button>
    </div>
  );
};

export default CloneCourse;
