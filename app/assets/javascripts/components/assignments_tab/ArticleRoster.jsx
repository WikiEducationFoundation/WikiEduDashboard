import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { StateBadge } from './CellDetails';
import { StageTracker, WorkLinks } from './ArticleParts';
import { StudentHeaders, useStudentSort } from './StudentSort';
import { articleStatusLabel, formatDate, sortStudents } from './assignmentHelpers';

// The assigned article's drawer: one row per student and article, with how
// far along it is, where to see the work, and when the student got it. A
// student with several articles spans several rows. Sortable by any of the
// student columns.
const ArticleRoster = ({ students, cellsByUser, studentPath, showNames }) => {
  const { sort, sortBy } = useStudentSort();
  return (
    <table className="table assignments-tab__article-roster">
      <thead>
        <tr>
          <StudentHeaders showNames={showNames} sort={sort} sortBy={sortBy} />
          <th>{I18n.t('assignments.article_link')}</th>
          <th>{I18n.t('assignments_tab.progress')}</th>
          <th>{I18n.t('lti.assignment_view.article_work.header')}</th>
          <th>{I18n.t('assignments_tab.assigned')}</th>
        </tr>
      </thead>
      <tbody>
        {sortStudents(students, cellsByUser, sort).map((student) => {
          const cell = cellsByUser[student.id];
          const rowSpan = Math.max(cell.articles.length, 1);
          const studentCells = (
            <>
              {showNames && <td rowSpan={rowSpan}>{student.real_name}</td>}
              <td rowSpan={rowSpan} className="assignments-tab__student-cell">
                <Link to={studentPath(student)}>{student.username}</Link>
              </td>
              <td rowSpan={rowSpan} className="assignments-tab__student-status">
                <StateBadge cell={cell} />
              </td>
            </>
          );
          if (cell.articles.length === 0) {
            return (
              <tr key={student.id}>
                {studentCells}
                <td colSpan={4} className="assignments-tab__no-article">
                  {I18n.t('lti.assignment_view.no_article_yet')}
                </td>
              </tr>
            );
          }
          return (
            <Fragment key={student.id}>
              {cell.articles.map((article, index) => {
                const status = article.status_updated_at ? articleStatusLabel(article.status) : '';
                return (
                  <tr key={article.assignment_id}>
                    {index === 0 && studentCells}
                    <td>
                      <a href={article.url} target="_blank" rel="noopener noreferrer">{article.title}</a>
                      {status && <div className="assignments-tab__article-status">{status}</div>}
                    </td>
                    <td><StageTracker stages={article.stages} /></td>
                    <td><WorkLinks article={article} /></td>
                    <td className="assignments-tab__date">{formatDate(article.assigned_at)}</td>
                  </tr>
                );
              })}
            </Fragment>
          );
        })}
      </tbody>
    </table>
  );
};

ArticleRoster.propTypes = {
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  studentPath: PropTypes.func.isRequired,
  showNames: PropTypes.bool.isRequired,
};

export default ArticleRoster;
