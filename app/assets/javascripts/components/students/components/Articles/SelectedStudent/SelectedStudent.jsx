import React from 'react';
import PropTypes from 'prop-types';

// Components
import Header from './Header.jsx';
import AssignmentsList from './AssignmentsList/AssignmentsList.jsx';
import NoAssignments from './NoAssignments.jsx';
import StudentExercisesList from './ExercisesList/StudentExercisesList.jsx';
import StudentRevisionsList from './RevisionsList/StudentRevisionsList.jsx';
import EditedUnassignedArticles from './EditedUnassignedArticles/EditedUnassignedArticles.jsx';

// Utils
import { processAssignments } from '@components/overview/my_articles/utils/processAssignments';
import setUnassignedArticles from '@components/students/utils/setUnassignedArticles';

export const SelectedStudent = ({
  groupedArticles, assignments, course, current_user, fetchArticleDetails,
  fetchUserRevisions, hasExercisesOrTrainings, openKey, selected, setUploadFilters,
  sort, sortUsers, toggleUI, trainingStatus, wikidataLabels, userRevisions
}) => {
  const {
    assigned, reviewing
  } = processAssignments({ assignments, course, current_user: selected });
  const unassigned = setUnassignedArticles(groupedArticles, assignments, selected);
  const showArticleId = Number(location.search.split('showArticle=')[1]);

  return (
    <article className="assignments-list">
      <Header
        assignments={assignments}
        course={course}
        current_user={current_user}
        reviewing={reviewing}
        selected={selected}
        wikidataLabels={wikidataLabels}
      />

      {
        !!assigned.length && <AssignmentsList
          assignments={assigned}
          course={course}
          current_user={current_user}
          fetchArticleDetails={fetchArticleDetails}
          title={I18n.t('instructor_view.assigned_articles')}
          user={selected}
        />
      }

      {
        !!reviewing.length && <AssignmentsList
          assignments={reviewing}
          course={course}
          current_user={current_user}
          fetchArticleDetails={fetchArticleDetails}
          title={I18n.t('instructor_view.reviewing_articles')}
          user={selected}
        />
      }

      {
        !assigned.length && !reviewing.length && <NoAssignments />
      }

      {
        hasExercisesOrTrainings && (
          <StudentExercisesList
            course={course}
            current_user={current_user}
            openKey={openKey}
            sort={sort}
            sortUsers={sortUsers}
            selected={selected}
            toggleUI={toggleUI}
            trainingStatus={trainingStatus}
            wikidataLabels={wikidataLabels}
          />
        )
      }

      {
        !!unassigned.length && (
          <EditedUnassignedArticles
            articles={unassigned}
            course={course}
            user={selected}
            current_user={current_user}
            showArticleId={showArticleId}
            fetchArticleDetails={fetchArticleDetails}
            title="Other Edited Articles"
          />
        )
      }

      <StudentRevisionsList
        course={course}
        current_user={current_user}
        fetchUserRevisions={fetchUserRevisions}
        openKey={openKey}
        setUploadFilters={setUploadFilters}
        sort={sort}
        sortUsers={sortUsers}
        student={selected}
        trainingStatus={trainingStatus}
        wikidataLabels={wikidataLabels}
        userRevisions={userRevisions}
      />
    </article>
  );
};

SelectedStudent.propTypes = {
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func.isRequired,
  fetchUserRevisions: PropTypes.func.isRequired,
  groupedArticles: PropTypes.object.isRequired,
  selected: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object,
  userRevisions: PropTypes.object,
  weeks: PropTypes.array
};

export default SelectedStudent;
