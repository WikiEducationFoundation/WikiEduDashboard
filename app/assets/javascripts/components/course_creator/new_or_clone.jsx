import React from 'react';
import { Link } from 'react-router-dom';
import CourseUtils from '../../utils/course_utils.js';

const NewOrClone = ({ cloneClasss, chooseNewCourseAction, showCloneChooserAction, stringPrefix }) => {
  return (
    <div className={cloneClasss}>
      <button className="button dark" onClick={chooseNewCourseAction}>{CourseUtils.i18n('creator.create_label', stringPrefix)}</button>
      <button className="button dark" onClick={showCloneChooserAction}>{CourseUtils.i18n('creator.clone_previous', stringPrefix)}</button>
      <Link className="button right" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
    </div>
  );
};

export default NewOrClone;
