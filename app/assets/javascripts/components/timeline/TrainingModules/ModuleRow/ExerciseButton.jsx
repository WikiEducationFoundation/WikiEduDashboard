import React from 'react';
import { Link } from 'react-router-dom';

export const ExerciseButton = ({ module, isStaff }) => {
  // An in-app exercise (eg fact verification) is a nested route of the course
  // SPA, so link to it with React Router to keep the student in-app (no
  // reload). Instructional staff also get the link to everyone's submissions.
  if (module.exercise_url) {
    return (
      <td className="block__training-modules-table__module-exercise-button">
        <Link className="button" to={module.exercise_url}>
          {I18n.t('training.open_exercise')}
        </Link>
        {isStaff && (
          <Link
            className="block__training-modules-table__responses-link"
            to={`${module.exercise_url}/responses`}
          >
            {I18n.t('claim_verification.responses.heading')}
          </Link>
        )}
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
