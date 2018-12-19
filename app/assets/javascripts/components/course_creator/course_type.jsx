import React from 'react';
import _ from 'lodash';

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
            {_.map(courseTypes, (program) => {
                return (
                    <div key={program.name} onClick={wizardAction.bind(null, program.type)} className="program-description">
                        <h4><strong>{program.name}</strong></h4>
                        <p>
                            {program.description}
                        </p>
                    </div>
                );
            })}
        </div>
    );
};

export default CourseType;
