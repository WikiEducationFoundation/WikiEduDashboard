import React from 'react';

export const ExerciseButton = ({ module }) => {
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
