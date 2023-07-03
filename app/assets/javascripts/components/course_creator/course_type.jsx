import React from 'react';
import { map } from 'lodash-es';
import SelectableBox from '../common/selectable_box';

const CourseType = ({ wizardClass, wizardAction }) => {
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
      {map(courseTypes, (program) => {
        return (
          <SelectableBox key={program.name} onClick={wizardAction.bind(null, program.type)} heading={program.name} description={program.description} />
        );
      })}
    </div>
  );
};

export default CourseType;
