import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { StateBadge } from './CellDetails';
import { StageTracker, WorkLinks } from './ArticleParts';
import { articleStatusLabel, formatDate, studentName } from './assignmentHelpers';

// The assigned article's drawer: one row per student and article, with how
// far along it is, where to see the work, and when the student got it. A
// student with several articles spans several rows.
const ArticleRoster = ({ students, cellsByUser, studentPath }) => (
  <table className="table assignments-tab__article-roster">
    <thead>
      <tr>
        <th>{I18n.t('lti.assignment_view.roster.student')}</th>
        <th>{I18n.t('assignments.article_link')}</th>
        <th>{I18n.t('assignments_tab.progress')}</th>
        <th>{I18n.t('lti.assignment_view.article_work.header')}</th>
        <th>{I18n.t('assignments_tab.assigned')}</th>
      </tr>
    </thead>
    <tbody>
      {students.map((student) => {
        const cell = cellsByUser[student.id];
        const done = cell.exercises.filter(exercise => exercise.completed).length;
        const studentCell = (
          <td rowSpan={Math.max(cell.articles.length, 1)} className="assignments-tab__student-cell">
            <Link to={studentPath(student)}>{studentName(student)}</Link>
            <div><StateBadge cell={cell} /></div>
            {cell.exercises.length > 0 && (
              <div className="assignments-tab__exercise-count">
                {I18n.t('lti.student_overview.exercises')}: {done} / {cell.exercises.length}
              </div>
            )}
          </td>
        );
        if (cell.articles.length === 0) {
          return (
            <tr key={student.id}>
              {studentCell}
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
                  {index === 0 && studentCell}
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

ArticleRoster.propTypes = {
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  studentPath: PropTypes.func.isRequired,
};

export default ArticleRoster;
