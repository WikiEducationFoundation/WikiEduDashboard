import React from 'react';
import { map } from 'lodash-es';
import SelectableBox from '../common/selectable_box';
import { Link } from 'react-router-dom';

const CourseType = ({ back, hasClonableCourses, wizardClass, wizardAction }) => {
  const courseTypes = [
    {
      name: I18n.t('courses.creator.course_types.basic_course_name'),
      type: 'BasicCourse',
      description: I18n.t('courses.creator.course_types.basic_course_description')
    },
    {
      name: I18n.t('courses.creator.course_types.edit_a_thon_name'),
      type: 'Editathon',
      description: I18n.t('courses.creator.course_types.edit_a_thon_description')
    },
    {
      name: I18n.t('courses.creator.course_types.article_scoped_program_name'),
      type: 'ArticleScopedProgram',
      description: I18n.t('courses.creator.course_types.article_scoped_program_description')
    }
  ];

  return (
    <div className={wizardClass}>
      <div className={wizardClass} style={{ paddingBottom: '20px' }}>
        {map(courseTypes, (program) => {
          return (
            <SelectableBox key={program.name} onClick={wizardAction.bind(null, program.type)} heading={program.name} description={program.description} />
          );
        })}
      </div>
      { hasClonableCourses && <button className="button dark" onClick={back}>{I18n.t('application.back')}</button> }
      <Link style={{ marginRight: !hasClonableCourses ? '6em' : '' }} className="button right" to="/" id="course_cancel">{I18n.t('application.cancel')}</Link>
    </div>
  );
};

export default CourseType;
