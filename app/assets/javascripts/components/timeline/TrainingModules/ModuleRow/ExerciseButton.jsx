import React, { useState } from 'react';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';
import { verifyExerciseArticle } from '~/app/assets/javascripts/actions/training_actions';
import { fetchTrainingModuleExercisesByUser } from '~/app/assets/javascripts/actions/exercises_actions';
import { fetchTimeline } from '~/app/assets/javascripts/actions/timeline_actions';
import ArticleTitleInputModal from './ModuleStatus/ArticleTitleInputModal';

export const ExerciseButton = ({ module, isStaff, course, verifyArticle, fetchExercises, refreshTimeline }) => {
  const [modalOpen, setModalOpen] = useState(false);

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

  if (module.article_title_input) {
    const articleTitle = module.flags?.exercise_article_title;
    const isMarkedComplete = !!module.flags?.marked_complete;

    if (articleTitle && isMarkedComplete) {
      return (
        <td className="block__training-modules-table__module-exercise-button">
          <a
            href={module.exercise_article_url}
            target="_blank"
            rel="noopener noreferrer"
            title={articleTitle}
          >
            {articleTitle.split(' ').slice(0, 2).join(' ')}{articleTitle.split(' ').length > 2 ? '…' : ''}
          </a>
        </td>
      );
    }

    const handleVerify = (block_id, module_id, article_title) => {
      return verifyArticle(block_id, module_id, article_title);
    };

    return (
      <td className="block__training-modules-table__module-exercise-button">
        {modalOpen && (
          <ArticleTitleInputModal
            block_id={module.block_id}
            module_id={module.slug}
            verifyArticle={handleVerify}
            onVerified={() => {
              setModalOpen(false);
              // Verifying completes the exercise, which the timeline shows.
              refreshTimeline(course.slug);
              fetchExercises(course.id);
            }}
            onClose={() => setModalOpen(false)}
          />
        )}
        <button className="button small" onClick={() => setModalOpen(true)}>
          {I18n.t('training.article_title_input.submit')}
        </button>
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

const mapStateToProps = state => ({
  course: state.course
});

const mapDispatchToProps = dispatch => ({
  verifyArticle: (block_id, module_id, article_title) => dispatch(verifyExerciseArticle(block_id, module_id, article_title)),
  fetchExercises: course_id => dispatch(fetchTrainingModuleExercisesByUser(course_id)),
  refreshTimeline: course_slug => dispatch(fetchTimeline(course_slug))
});

export default connect(mapStateToProps, mapDispatchToProps)(ExerciseButton);
