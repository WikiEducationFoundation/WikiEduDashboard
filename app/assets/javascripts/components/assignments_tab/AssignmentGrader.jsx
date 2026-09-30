import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import CellDetails, { StateBadge } from './CellDetails';
import { matchesFilter, neighbors, reachedStage, studentName } from './assignmentHelpers';
import { onEnterOrSpace } from '../../utils/keyboard_handlers';

const isTyping = target => ['INPUT', 'SELECT', 'TEXTAREA'].includes(target.tagName)
  || target.isContentEditable;

// One assignment, one student at a time: the assignment's heading with
// previous/next through the students beside it (also on the ← and → keys),
// then the student list on the side (the same students the roster's filter
// shows) and that student's work on the assignment.
const AssignmentGrader = ({ header, item, students, cellsByUser, itemPath }) => {
  const { username } = useParams();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  // The list the grader came from: a status filter, or (for the assigned
  // article) the students who haven't reached a stage.
  const filter = searchParams.get('filter') || 'all';
  const missing = searchParams.get('missing');
  const query = searchParams.toString() ? `?${searchParams}` : '';
  const shown = students.filter(student => matchesFilter(cellsByUser[student.id], filter)
    && (!missing || !reachedStage(cellsByUser[student.id], missing)));
  const { index, previous, next } = neighbors(shown, username);
  const student = students.find(candidate => candidate.username === username);

  const goTo = (target) => {
    if (target) { navigate(`${itemPath}/${encodeURIComponent(target.username)}${query}`); }
  };

  useEffect(() => {
    const onKeyDown = (event) => {
      if (isTyping(event.target) || event.altKey || event.ctrlKey || event.metaKey) { return; }
      if (event.key === 'ArrowLeft') { goTo(previous); }
      if (event.key === 'ArrowRight') { goTo(next); }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  });

  return (
    <>
      <div className="assignments-tab__grader-top">
        {header}
        <div className="assignments-tab__grader-nav">
          <button type="button" className="button border" disabled={!previous} onClick={() => goTo(previous)}>
            ← {I18n.t('articles.previous')}
          </button>
          {index >= 0 && <span className="assignments-tab__position">{index + 1} / {shown.length}</span>}
          <button type="button" className="button border" disabled={!next} onClick={() => goTo(next)}>
            {I18n.t('articles.next')} →
          </button>
        </div>
      </div>
      <section className="users-articles assignments-tab__grader">
        <aside className="student-selection">
          <ul>
            {shown.map(candidate => (
              // Same keyboard-accessible list item pattern as the Students tab's
              // student selection, which shares this CSS.
              // eslint-disable-next-line jsx-a11y/no-noninteractive-element-to-interactive-role
              <li role="button" tabIndex={0} key={candidate.id}
                aria-pressed={candidate.username === username}
                className={`student ${candidate.username === username ? 'selected' : ''}`}
                onClick={() => goTo(candidate)}
                onKeyDown={onEnterOrSpace(() => goTo(candidate))}
              >
                {candidate.real_name && <p className="real-name">{candidate.real_name}</p>}
                <p>{candidate.username}</p>
                <StateBadge cell={cellsByUser[candidate.id]} />
              </li>
            ))}
          </ul>
        </aside>
        <article className="student-details">
          {student && (
            <div className="assignments-tab__student">
              <div className="assignments-tab__student-header">
                <h4>{studentName(student)}</h4>
                <StateBadge cell={cellsByUser[student.id]} />
              </div>
              <CellDetails cell={cellsByUser[student.id]} item={item} />
            </div>
          )}
        </article>
      </section>
    </>
  );
};

AssignmentGrader.propTypes = {
  header: PropTypes.node,
  item: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  itemPath: PropTypes.string.isRequired,
};

export default AssignmentGrader;
