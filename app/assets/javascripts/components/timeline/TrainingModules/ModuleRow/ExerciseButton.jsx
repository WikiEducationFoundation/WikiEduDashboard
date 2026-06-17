import React from 'react';

export const ExerciseButton = ({ module }) => {
  // An in-app exercise (eg fact verification) links to a course page in the
  // dashboard rather than to an external sandbox.
  if (module.exercise_url) {
    return (
      <td className="block__training-modules-table__module-exercise-button">
        <a className="button" href={module.exercise_url}>
          {I18n.t('training.open_exercise')}
        </a>
      </td>
    );
  }

  if (!module.sandbox_url) { return null; }

  let sandboxUrl = module.sandbox_url;
  if (module.sandbox_preload) { sandboxUrl = `${sandboxUrl}?veaction=edit&preload=${module.sandbox_preload}`; }

  return (
    <td className="block__training-modules-table__module-exercise-button">
      <a className="button" href={sandboxUrl} target="_blank">
        {I18n.t('training.exercise_sandbox')}
      </a>
    </td>
  );
};

export default ExerciseButton;
