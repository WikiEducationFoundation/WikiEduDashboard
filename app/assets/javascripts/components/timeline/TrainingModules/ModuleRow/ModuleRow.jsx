import React from 'react';
import PropTypes from 'prop-types';

import {
  DISCUSSION_KIND, EXERCISE_KIND, TRAINING_MODULE_KIND
} from '../../../../constants';

// Components
import ModuleStatus from './ModuleStatus/ModuleStatus';
import ModuleLink from './ModuleLink';
import ModuleName from './ModuleName';

const calcProgressClass = (progress) => {
  const linkStart = 'timeline-module__';
  if (progress === 'Complete') {
    return `${linkStart}progress-complete `;
  }
  return `${linkStart}in-progress `;
};

export const ModuleRow = ({ isStudent, module, trainingLibrarySlug }) => {
  const isTrainingModule = module.kind === TRAINING_MODULE_KIND;
  const isExercise = module.kind === EXERCISE_KIND;
  const isDiscussion = module.kind === DISCUSSION_KIND;

  let iconClassName = 'icon ';
  let progressClass;
  let linkText;

  if (isExercise || isDiscussion) {
    progressClass = calcProgressClass(module.module_progress);
    linkText = 'View';
    iconClassName += 'icon-rt_arrow_purple_training';
  } else if (isTrainingModule && module.module_progress) {
    progressClass = calcProgressClass(module.module_progress);
    const completedText = I18n.t('training_status.completed');
    const viewText = I18n.t('training_status.view');
    const continueText = I18n.t('training_status.continue');

    linkText = module.module_progress === completedText ? viewText : continueText;
    iconClassName += module.module_progress === completedText ? 'icon-check' : 'icon-rt_arrow_purple_training';
  } else {
    linkText = 'Start';
    iconClassName += 'icon-rt_arrow_purple_training';
  }

  progressClass += ' block__training-modules-table__module-progress ';
  if (module.overdue === true) progressClass += ' overdue';
  if (module.deadline_status === 'complete') progressClass += ' complete';

  const link = `/training/${trainingLibrarySlug}/${module.slug}`;
  return (
    <tr className="training-module">
      <ModuleName {...module} isExercise={isExercise} />
      { isStudent ? <ModuleStatus {...module} progressClass={progressClass} /> : null }
      <ModuleLink
        iconClassName={iconClassName}
        link={link}
        linkText={linkText}
        module_progress={module.module_progress}
      />
    </tr>
  );
};

ModuleRow.propTypes = {
  isStudent: PropTypes.bool,
  module: PropTypes.object.isRequired,
  trainingLibrarySlug: PropTypes.string.isRequired
};

export default ModuleRow;
