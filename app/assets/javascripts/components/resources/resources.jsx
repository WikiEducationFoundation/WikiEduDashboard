
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import CourseLink from '../common/course_link.jsx';
import { getWeeksArray } from '../../selectors';
import Block from '../timeline/block';
import TrainingModules from '../timeline/training_modules';
import Handouts from './handouts';

const Resources = ({ weeks, current_user, course }) => {
  const trainingLibrarySlug = course.training_library_slug;
  let instructorModulesLink;
  if (current_user.isInstructor && Features.wikiEd) {
    instructorModulesLink = <CourseLink to={'/training/instructors'} className="button pull-right">Instructor orientation modules</CourseLink>;
  }
  const blocks = _.flatten(weeks.map(week => week.blocks));
  const modules = _.compact(_.flatten(blocks.map(block => block.training_modules)));

  let additionalResources;
  const additionalResourcesBlock = blocks.find(block => block.title.match(/Additional Resources/));
  if (additionalResourcesBlock) {
    additionalResources = (
      <div className="list-unstyled container mt2 mb2">
        <Block block={additionalResourcesBlock} trainingLibrarySlug={trainingLibrarySlug} />
      </div>
    );
  }
  let assignedModules;
  if (modules.length) {
    assignedModules = (
      <TrainingModules
        block_modules={modules}
        trainingLibrarySlug={trainingLibrarySlug}
        header="Assigned trainings"
      />
    );
  }
  let additionalModules;
  if (Features.wikiEd) {
     additionalModules = (
       <CourseLink to={`/training/${trainingLibrarySlug}`} className="button pull-right ml1">Additional training modules</CourseLink>
    );
  } else {
    additionalModules = (
      <CourseLink to={'/training'} className="button dark mb1">{I18n.t('training.training_library')}</CourseLink>
    );
  }

  return (
    <div id="resources" className="w75">
      <div className="section-header">
        <h3>{I18n.t('resources.header')}</h3>
        <div id="training-modules" className="container">
          {assignedModules}
          {additionalModules}
          {instructorModulesLink}
        </div>
        {additionalResources}
        <Handouts trainingLibrarySlug={trainingLibrarySlug} blocks={blocks} />
      </div>
    </div>
  );
};

const mapStateToProps = state => ({
  weeks: getWeeksArray(state)
});

export default connect(mapStateToProps)(Resources);
