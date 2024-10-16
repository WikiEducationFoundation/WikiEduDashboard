import React, { useEffect } from 'react';
import { connect } from 'react-redux';

import { getWeeksArray } from '../../selectors';
import Block from '../timeline/block';
import TrainingModules from '../timeline/TrainingModules/TrainingModules';
import Handouts from './handouts';
import Templates from './templates';
import Videos from './videos';
import { BLOCK_KIND_RESOURCES } from '../../constants/timeline';
import { getModulesAndBlocksFromWeeks } from '../util/helpers';

const moduleByExercises = (modules) => {
  const orderedSteps = [
    'Complete your Bibliography',
    'Create in the sandbox',
    'Expand your Draft',
    'Move your Work',
    'Other Assigned Training Modules',
    'Discussions',
    'Exercises',
  ];
  const [
    COMPLETE_YOUR_BIBLIOGRAPHY,
    CREATE_IN_THE_SANDBOX,
    EXPAND_YOUR_DRAFT,
    MOVE_YOUR_WORK,
    OTHER,
    DISCUSSIONS,
<<<<<<< HEAD
    EXERCISES,
=======
    EXERCISES
>>>>>>> f3815a4f0 (Done)
  ] = orderedSteps;
  const mapping = {
    'wikipedia-essentials': COMPLETE_YOUR_BIBLIOGRAPHY,
    'evaluating-articles': COMPLETE_YOUR_BIBLIOGRAPHY,
    'how-to-edit': CREATE_IN_THE_SANDBOX,
    'drafting-in-sandbox': CREATE_IN_THE_SANDBOX,
    'drafting-in-sandbox-group': CREATE_IN_THE_SANDBOX,
    sources: CREATE_IN_THE_SANDBOX,
    plagiarism: EXPAND_YOUR_DRAFT,
    'moving-to-mainspace': MOVE_YOUR_WORK,
    'moving-to-mainspace-group': MOVE_YOUR_WORK,
    'sources-and-plagiarism-discussion': DISCUSSIONS,
    'content-gap-discussion': DISCUSSIONS,
    'thinking-about-wikipedia-discussion': DISCUSSIONS,
    'evaluate-wikipedia-exercise': EXERCISES,
    'choose-topic-from-list-exercise': EXERCISES,
    'add-to-article-exercise': EXERCISES,
    'did-you-know-exercise': EXERCISES,
    'continue-improving-exercise': EXERCISES,
    'in-class-presentation-exercise': EXERCISES,
<<<<<<< HEAD
    'reflective-essay-exercise': EXERCISES,
=======
    'reflective-essay-exercise': EXERCISES
>>>>>>> f3815a4f0 (Done)
  };

  const categorized = modules.reduce((acc, block) => {
    const key = mapping[block.slug] || OTHER;
    acc[key] = acc[key] ? [...acc[key], block] : [block];
    return acc;
  }, {});

  return orderedSteps.map((step) => {
    return [step, categorized[step]];
  });
};

const Resources = ({ weeks, current_user, course }) => {
  // setting page title
  useEffect(() => {
    document.title = `${course.title} - ${I18n.t('resources.label')}`;
  }, []);

  const trainingLibrarySlug = course.training_library_slug;
  let instructorModulesLink;
  if (current_user.isInstructor && Features.wikiEd) {
<<<<<<< HEAD
    instructorModulesLink = (
      <a href={'/training/instructors'} className="button pull-right">
        {I18n.t('training.orientation_modules')}
      </a>
    );
=======
    instructorModulesLink = <a href={'/training/instructors'} className="button pull-right">Instructor orientation modules</a>;
>>>>>>> f3815a4f0 (Done)
  }

  const { blocks, modules } = getModulesAndBlocksFromWeeks(weeks);
  let additionalResources;
<<<<<<< HEAD
  const additionalResourcesBlocks = blocks.filter(
    block => block.kind === BLOCK_KIND_RESOURCES
  );
  if (additionalResourcesBlocks) {
    additionalResources = (
      <div className="list-unstyled container mt2 mb2">
        {additionalResourcesBlocks.map(block => (
          <Block
            key={block.id}
            block={block}
            trainingLibrarySlug={trainingLibrarySlug}
          />
        ))}
=======
  const additionalResourcesBlocks = blocks.filter(block => block.kind === BLOCK_KIND_RESOURCES);
  if (additionalResourcesBlocks) {
    additionalResources = (
      <div className="list-unstyled container mt2 mb2">
        {additionalResourcesBlocks.map(block => <Block key={block.id} block={block} trainingLibrarySlug={trainingLibrarySlug} />)}
>>>>>>> f3815a4f0 (Done)
      </div>
    );
  }
  let assignedModules;
  if (modules.length) {
    const categorized = moduleByExercises(modules);
    assignedModules = categorized.map(([title, categorizedModules]) => {
      if (categorizedModules) {
<<<<<<< HEAD
        return (
          <TrainingModules
            block_modules={categorizedModules}
            header={title}
            isStudent={current_user.isStudent}
            key={title}
            trainingLibrarySlug={trainingLibrarySlug}
          />
        );
      }
      return null;
    });
=======
        return (<TrainingModules
          block_modules={categorizedModules}
          header={title}
          isStudent={current_user.isStudent}
          key={title}
          trainingLibrarySlug={trainingLibrarySlug}
        />);
      }
      return null;
    }
    );
>>>>>>> f3815a4f0 (Done)
  }
  let additionalModules;
  if (Features.wikiEd) {
    additionalModules = (
<<<<<<< HEAD
      <a
        href={`/training/${trainingLibrarySlug}`}
        className="button pull-right ml1"
      >
        {I18n.t('training.additional_training')}
      </a>
    );
  } else {
    additionalModules = (
      <a href={'/training'} className="button dark mb1">
        {I18n.t('training.training_library')}
      </a>
=======
      <a href={`/training/${trainingLibrarySlug}`} className="button pull-right ml1">Additional training modules</a>
    );
  } else {
    additionalModules = (
      <a href={'/training'} className="button dark mb1">{I18n.t('training.training_library')}</a>
>>>>>>> f3815a4f0 (Done)
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
<<<<<<< HEAD
        {Features.wikiEd && <Videos />}
        {Features.wikiEd && <Templates />}
        {Features.wikiEd && (
          <Handouts trainingLibrarySlug={trainingLibrarySlug} blocks={blocks} />
        )}
=======
        { Features.wikiEd && <Videos /> }
        { Features.wikiEd && <Templates /> }
        { Features.wikiEd && <Handouts trainingLibrarySlug={trainingLibrarySlug} blocks={blocks} /> }
>>>>>>> f3815a4f0 (Done)
      </div>
    </div>
  );
};

const mapStateToProps = state => ({
<<<<<<< HEAD
  weeks: getWeeksArray(state),
=======
  weeks: getWeeksArray(state)
>>>>>>> f3815a4f0 (Done)
});

export default connect(mapStateToProps)(Resources);
