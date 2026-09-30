import '../testHelper';
import {
  filterLabel, isLate, itemTitle, matchesFilter, neighbors, studentName
} from '../../app/assets/javascripts/components/assignments_tab/assignmentHelpers';

const React = require('react');
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;
const { createRoot } = require('react-dom/client');
const { MemoryRouter, Routes, Route } = require('react-router-dom');
const { act } = require('react-dom/test-utils');
const AssignmentRoster = require('../../app/assets/javascripts/components/assignments_tab/AssignmentRoster').default;
const AssignmentGrader = require('../../app/assets/javascripts/components/assignments_tab/AssignmentGrader').default;

const students = [
  { id: 1, username: 'Amy' },
  { id: 2, username: 'Bo', real_name: 'Bo Real' },
  { id: 3, username: 'Cy' },
];

describe('assignmentHelpers', () => {
  test('neighbors finds who comes before and after a student', () => {
    expect(neighbors(students, 'Bo')).toEqual({ index: 1, previous: students[0], next: students[2] });
    expect(neighbors(students, 'Amy').previous).toBeNull();
    expect(neighbors(students, 'Cy').next).toBeNull();
    expect(neighbors(students, 'Nobody').index).toBe(-1);
  });

  test('matchesFilter filters by state, or overdue', () => {
    const cell = { state: 'in_progress', overdue: true };
    expect(matchesFilter(cell, 'all')).toBe(true);
    expect(matchesFilter(cell, 'in_progress')).toBe(true);
    expect(matchesFilter(cell, 'complete')).toBe(false);
    expect(matchesFilter(cell, 'overdue')).toBe(true);
    expect(matchesFilter({ state: 'complete' }, 'overdue')).toBe(false);
  });

  test('isLate compares completion with the end of the due date', () => {
    expect(isLate('2026-02-14T20:00:00Z', '2026-02-15')).toBe(false);
    expect(isLate('2026-02-17T09:00:00Z', '2026-02-15')).toBe(true);
    expect(isLate(null, '2026-02-15')).toBe(false);
    expect(isLate('2026-02-17T09:00:00Z', undefined)).toBe(false);
  });

  test('labels module items by name and the rest from translations', () => {
    expect(itemTitle({ kind: 'training', title: 'Wikipedia essentials' })).toBe('Wikipedia essentials');
    expect(itemTitle({ kind: 'article', article_stage: 'live' })).toBe('Live article');
    expect(itemTitle({ kind: 'article', article_stage: 'draft' })).toBe('Draft sandbox');
    expect(itemTitle({ kind: 'peer_review' })).toBe('Peer reviews');
    expect(filterLabel('overdue')).toBe('Overdue');
  });

  test('studentName shows the real name when there is one', () => {
    expect(studentName(students[1])).toBe('Bo Real (Bo)');
    expect(studentName(students[0])).toBe('Amy');
  });
});

describe('Assignments tab views', () => {
  const item = { key: 'training-a', kind: 'training', title: 'Training A', due_date: '2026-02-15' };
  const cellsByUser = {
    1: { user_id: 1, state: 'complete', completed_at: '2026-02-17T09:00:00Z' },
    2: { user_id: 2, state: 'in_progress', slide_progress: 0.5, overdue: true },
    3: { user_id: 3, state: 'not_started', overdue: true },
  };
  const itemPath = '/courses/S/T/assignments/training-a';
  let container;
  let root;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    document.body.removeChild(container);
  });

  const render = (path, element, routePath) => {
    act(() => {
      root.render(
        <MemoryRouter initialEntries={[path]}>
          <Routes><Route path={routePath} element={element} /></Routes>
        </MemoryRouter>
      );
    });
  };

  test('the roster lists every student with status and progress', () => {
    const roster = <AssignmentRoster item={item} students={students} cellsByUser={cellsByUser} itemPath={itemPath} />;
    render(itemPath, roster, itemPath);
    const rows = container.querySelectorAll('tbody tr');
    expect(rows.length).toBe(3);
    expect(rows[0].textContent).toContain('Completed');
    expect(rows[0].textContent).toContain('Late');
    expect(rows[1].textContent).toContain('50%');
    expect(rows[1].textContent).toContain('Overdue');
  });

  test('the roster filter narrows the students and carries into the grader links', () => {
    const roster = <AssignmentRoster item={item} students={students} cellsByUser={cellsByUser} itemPath={itemPath} />;
    render(`${itemPath}?filter=overdue`, roster, itemPath);
    const links = [...container.querySelectorAll('tbody a')].map(a => a.getAttribute('href'));
    expect(links).toEqual([`${itemPath}/Bo?filter=overdue`, `${itemPath}/Cy?filter=overdue`]);
  });

  test('the grader shows one student with previous and next', () => {
    const grader = <AssignmentGrader item={item} students={students} cellsByUser={cellsByUser} itemPath={itemPath} />;
    render(`${itemPath}/Bo`, grader, `${itemPath}/:username`);
    expect(container.querySelector('.assignments-tab__student h4').textContent).toBe('Bo Real (Bo)');
    expect(container.querySelector('.assignments-tab__grader-nav').textContent).toContain('2 / 3');
    const [previous, next] = container.querySelectorAll('.assignments-tab__grader-nav button');
    expect(previous.disabled).toBe(false);
    expect(next.disabled).toBe(false);
  });

  test('the grader moves to the next student on the right arrow key', () => {
    const grader = <AssignmentGrader item={item} students={students} cellsByUser={cellsByUser} itemPath={itemPath} />;
    render(`${itemPath}/Amy`, grader, `${itemPath}/:username`);
    act(() => {
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight' }));
    });
    expect(container.querySelector('.assignments-tab__student h4').textContent).toBe('Bo Real (Bo)');
  });
});
