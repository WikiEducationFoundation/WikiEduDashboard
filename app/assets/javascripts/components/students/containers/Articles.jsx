import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { generatePath } from 'react-router';
import { Route, Routes } from 'react-router-dom';
// Components
import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import Controls from '@components/students/components/Overview/Controls/Controls.jsx';
import StudentSelection from '@components/students/components/Articles/StudentSelection.jsx';
import SelectedStudent from '@components/students/components/Articles/SelectedStudent/SelectedStudent.jsx';
import NoSelectedStudent from '@components/students/components/Articles/NoSelectedStudent.jsx';

// Actions
import { fetchArticleDetails } from '~/app/assets/javascripts/actions/article_actions.js';

// Utils
import { getStudentUsers, getWeeksArray } from '~/app/assets/javascripts/selectors';
import { getModulesAndBlocksFromWeeks } from '@components/util/helpers';
import groupArticlesCoursesByUserId from '@components/students/utils/groupArticlesCoursesByUserId';
import ScrollToTopOnMount from '../../util/ScrollToTopOnMount';

const Articles = ({ articles, course, current_user, prefix, notify, sortSelect, sortUsers }) => {
  const dispatch = useDispatch();

  const assignments = useSelector(state => state.assignments.assignments);
  const openKey = useSelector(state => state.ui.openKey);
  const sort = useSelector(state => state.users.sort);
  const students = useSelector(state => getStudentUsers(state));
  const trainingStatus = useSelector(state => state.trainingStatus);
  const weeks = useSelector(state => getWeeksArray(state));
  const wikidataLabels = useSelector(state => state.wikidataLabels.labels);
  const userRevisions = useSelector(state => state.userRevisions);

  const [selected, setSelected] = useState({});

  useEffect(() => {
    // sets the title of this tab
    const header = I18n.t('instructor_view.article_assignments', { prefix });
    document.title = `${course.title} - ${header}`;
  });

  const selectStudent = (selectedStudent) => {
    setSelected({ selected: selectedStudent });
  };

  const generateArticlesUrl = (courseData) => {
    const [course_school, course_title] = courseData.slug.split('/');
    const root = '/courses/:course_school/:course_title/students/articles';
    return generatePath(root, { course_school, course_title });
  };

  const { modules } = getModulesAndBlocksFromWeeks(weeks);
  const hasExercisesOrTrainings = !!modules.length;
  const groupedArticles = groupArticlesCoursesByUserId(articles);
  if (!students.length) return null;
  const studentSelection = (
    <StudentSelection
      articlesUrl={generateArticlesUrl(course)}
      course={course}
      selected={selected}
      selectStudent={selectStudent}
      students={students}
    />
  );
  return (
    <>
      <ScrollToTopOnMount />
      <StudentsSubNavigation
        course={course}
        heading={I18n.t('instructor_view.article_assignments', { prefix })}
        prefix={prefix}
      />
      {
        current_user.isAdvancedRole
          ? (
            <Controls
              course={course}
              current_user={current_user}
              students={students}
              notify={notify}
              showOverviewFilters={false}
              sortSelect={sortSelect}
            />
          ) : null
      }
      <section className="users-articles">
        <aside className="student-selection">
          <Routes>
            <Route
              path=":username" element={studentSelection}
            />
            <Route
              path="*" element={studentSelection}
            />
          </Routes>
        </aside>
        <article className="student-details">
          <section className="assignments">
            <Routes>
              <Route
                path=":username"
                element={<SelectedStudent
                  assignments={assignments}
                  course={course}
                  current_user={current_user}
                  fetchArticleDetails={(articleId, courseId) => dispatch(fetchArticleDetails(articleId, courseId))}
                  groupedArticles={groupedArticles}
                  hasExercisesOrTrainings={hasExercisesOrTrainings}
                  openKey={openKey}
                  sort={sort}
                  sortUsers={sortUsers}
                  students={students}
                  trainingStatus={trainingStatus}
                  wikidataLabels={wikidataLabels}
                  userRevisions={userRevisions}
                  articlesUrl={generateArticlesUrl(course)}
                />
                }
              />
              <Route
                path="*"
                element={<NoSelectedStudent string_prefix={course.string_prefix} project={course.home_wiki.project} />}
              />
            </Routes>
          </section>
        </article>
      </section>
    </>
  );
};

Articles.propTypes = {
  articles: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  prefix: PropTypes.string.isRequired,
  sortSelect: PropTypes.func.isRequired,
  sortUsers: PropTypes.func.isRequired,
};

export default (Articles);
