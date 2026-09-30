import '../testHelper';

jest.mock('../../app/assets/javascripts/components/assignments_tab/AssignmentProgressAPI', () => ({
  fetchAssignmentProgress: jest.fn()
}));
import {
  filterLabel, isLate, itemTitle, matchesFilter, neighbors, studentName
} from '../../app/assets/javascripts/components/assignments_tab/assignmentHelpers';
import { rebaseHtml } from '../../app/assets/javascripts/components/assignments_tab/pagePreview';

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
const AssignmentList = require('../../app/assets/javascripts/components/assignments_tab/AssignmentList').default;
const { fetchAssignmentProgress } = require('../../app/assets/javascripts/components/assignments_tab/AssignmentProgressAPI');

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
    expect(itemTitle({ kind: 'article', key: 'article' })).toBe('Assigned article');
    expect(itemTitle({ kind: 'peer_review' })).toBe('Peer reviews');
    expect(filterLabel('overdue')).toBe('Overdue');
  });

  test('rebaseHtml points wiki-relative links and images at the wiki, opening links in a new tab', () => {
    const html = '<p><a href="/wiki/Telomere">T</a> <a href="#cite_note-1">1</a>'
      + '<img src="/static/logo.png"></p>';
    const rebased = new DOMParser().parseFromString(rebaseHtml(html, 'https://en.wikipedia.org'), 'text/html');
    const [wikiLink, footnote] = rebased.querySelectorAll('a');
    expect(wikiLink.getAttribute('href')).toBe('https://en.wikipedia.org/wiki/Telomere');
    expect(wikiLink.getAttribute('target')).toBe('_blank');
    expect(footnote.getAttribute('href')).toBe('#cite_note-1');
    expect(rebased.querySelector('img').getAttribute('src')).toBe('https://en.wikipedia.org/static/logo.png');
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

  test('clicking an assignment row opens its students in a drawer, and again closes it', async () => {
    const data = {
      items: [item, { key: 'article', kind: 'article' }],
      summary: [
        { key: 'training-a', complete: 1, in_progress: 1, not_started: 1, overdue: 2, total: 3 },
        { key: 'article', complete: 0, in_progress: 0, not_started: 3, overdue: 0, total: 3 },
      ],
    };
    fetchAssignmentProgress.mockResolvedValue({
      ...data, students, item_key: 'training-a', rows: Object.values(cellsByUser)
    });
    const list = <AssignmentList courseSlug="S/T" data={data} tabPath="/courses/S/T/assignments" />;
    render('/courses/S/T/assignments', list, '/courses/S/T/assignments');
    expect(container.querySelector('.drawer')).toBeNull();

    const row = container.querySelector('tbody tr');
    await act(async () => { row.click(); });
    expect(fetchAssignmentProgress).toHaveBeenCalledWith('S/T', 'training-a');
    expect(row.className).toBe('open');
    const drawerRows = container.querySelectorAll('.drawer tbody tr');
    expect(drawerRows.length).toBe(3);
    expect(container.querySelector('.drawer a').getAttribute('href'))
      .toBe('/courses/S/T/assignments/training-a/Amy');
    expect(container.querySelector('tbody tr button').getAttribute('aria-expanded')).toBe('true');

    await act(async () => { row.click(); });
    expect(container.querySelector('.drawer')).toBeNull();
  });

  test('the grader shows an article with its pages, exercises and a sandbox preview toggle', async () => {
    const articleItem = { key: 'article', kind: 'article' };
    const articleCells = {
      1: {
        user_id: 1,
        state: 'in_progress',
        articles: [{
          assignment_id: 9, title: 'Telomere', url: 'https://en.wikipedia.org/wiki/Telomere', live: false,
          pages: [{ kind: 'bibliography', url: 'https://en.wikipedia.org/wiki/User:Amy/Telomere/Bibliography', created: true }],
          stats: { characters: 0, references: 0, revisions: 0 }
        }],
        exercises: [{ slug: 'bib-ex', name: 'Bibliography exercise', completed: true },
                    { slug: 'outline-ex', name: 'Outline exercise', completed: false, overdue: true }],
      },
    };
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve({ parse: { text: '<p>Sources <a href="/wiki/Book">Book</a></p>' } })
    });
    const grader = <AssignmentGrader item={articleItem} students={[students[0]]} cellsByUser={articleCells} itemPath="/a/article" />;
    render('/a/article/Amy', grader, '/a/article/:username');

    const detail = container.querySelector('.assignments-tab__student');
    expect(detail.textContent).toContain('Telomere');
    expect(detail.textContent).toContain('Bibliography: Started');
    expect(detail.querySelectorAll('.assignments-tab__exercises li').length).toBe(2);
    expect(detail.querySelector('.assignments-tab__exercises').textContent).toContain('Overdue');

    const toggle = detail.querySelector('.assignments-tab__pages button');
    await act(async () => { toggle.click(); });
    expect(global.fetch.mock.calls[0][0]).toContain('page=User%3AAmy%2FTelomere%2FBibliography');
    expect(detail.querySelector('.assignments-tab__preview-content a').getAttribute('href'))
      .toBe('https://en.wikipedia.org/wiki/Book');
    expect(toggle.getAttribute('aria-expanded')).toBe('true');
  });
});
