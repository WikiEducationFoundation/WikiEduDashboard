import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useLocation, useParams, Navigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';

// Components
import Header from './Header.jsx';
import AssignmentsList from './AssignmentsList/AssignmentsList.jsx';
import NoAssignments from './NoAssignments.jsx';
import StudentExercisesList from './ExercisesList/StudentExercisesList.jsx';
import StudentRevisionsList from './RevisionsList/StudentRevisionsList.jsx';
import EditedUnassignedArticles from './EditedUnassignedArticles/EditedUnassignedArticles.jsx';

// Utils
import { processAssignments } from '@components/overview/my_articles/utils/processAssignments';
import setOtherEditedArticles from '@components/students/utils/setOtherEditedArticles';
import ArticleUtils from '../../../../../utils/article_utils';
import { fetchStudentArticles } from '../../../../../actions/articles_actions';
import { selectUserByUsernameParam } from '../../../../util/helpers.js';


export const SelectedStudent = ({
  assignments, course, current_user, fetchArticleDetails,
  hasExercisesOrTrainings, openKey,
  sort, sortUsers, trainingStatus, wikidataLabels, userRevisions,
  students, articlesUrl
}) => {
  const location = useLocation();
  const { username } = useParams();
  const selected = selectUserByUsernameParam(students, username);
  const dispatch = useDispatch();
  const studentArticles = useSelector(state => state.studentArticles);
  const selectedId = selected?.id;
  // Only ask for a student's articles if the student actually has edits
  const hasEdits = (selected?.character_sum_draft || 0) !== 0
    || (selected?.character_sum_ms || 0) !== 0
    || (selected?.character_sum_us || 0) !== 0;

  // Load the selected student's own articles. They are kept per student, apart
  // from the course-wide list, so this never touches the course-wide "See more".
  useEffect(() => {
    if (!selectedId || !hasEdits) { return; }
    dispatch(fetchStudentArticles(course.slug, selectedId));
  }, [selectedId, hasEdits, course.slug]);

  if (!selected) {
    // if user does not exist, then redirect to the articles home page
    return <Navigate to={articlesUrl} />;
  }
  const {
    assigned, reviewing
  } = processAssignments({ assignments, course, current_user: selected });

  // The articles this student edited, minus the ones already assigned to them
  const studentList = studentArticles[selected.id];
  const otherEditedArticles = setOtherEditedArticles(
    { [selected.id]: studentList?.articles || [] }, assignments, selected
  );
  // Keep the section visible while there are more pages to load
  const hasMoreStudentArticles = !!studentList && !studentList.limitReached;

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
          title={I18n.t(`instructor_view.${ArticleUtils.projectSuffix(course.home_wiki.project, 'assigned_articles')}`)}
          user={selected}
        />
      }

      {
        !!reviewing.length && <AssignmentsList
          assignments={reviewing}
          course={course}
          current_user={current_user}
          fetchArticleDetails={fetchArticleDetails}
          title={I18n.t(`instructor_view.${ArticleUtils.projectSuffix(course.home_wiki.project, 'reviewing_articles')}`)}
          user={selected}
        />
      }

      {
        !assigned.length && !reviewing.length && <NoAssignments student={selected} current_user={current_user} project={course.home_wiki.project} />
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
            trainingStatus={trainingStatus}
            wikidataLabels={wikidataLabels}
          />
        )
      }

      {
        (!!otherEditedArticles.length || hasMoreStudentArticles) && (
          <EditedUnassignedArticles
            articles={otherEditedArticles}
            course={course}
            user={selected}
            current_user={current_user}
            showArticleId={showArticleId}
            fetchArticleDetails={fetchArticleDetails}
            title="Other Edited Articles"
            wikidataLabels={wikidataLabels}
          />
        )
      }
      <StudentRevisionsList
        key={`student-revisions-${selected.id}`}
        course={course}
        student={selected}
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
  wikidataLabels: PropTypes.object,
  userRevisions: PropTypes.object,
  weeks: PropTypes.array
};

export default SelectedStudent;
