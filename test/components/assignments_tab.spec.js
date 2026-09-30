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
const ArticleRoster = require('../../app/assets/javascripts/components/assignments_tab/ArticleRoster').default;
const AssignmentsTabHandler = require('../../app/assets/javascripts/components/assignments_tab/AssignmentsTabHandler').default;
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

  const articleCells = {
    1: { user_id: 1, state: 'not_started', articles: [], exercises: [] },
    2: {
      user_id: 2, state: 'in_progress', exercises: [],
      articles: [{
        assignment_id: 5, title: 'Telomere', url: 'https://en.wikipedia.org/wiki/Telomere', live: false,
        pages: [{ kind: 'draft', url: 'https://en.wikipedia.org/wiki/User:Bo/Telomere', created: true }],
        stats: { characters: 0, references: 0, revisions: 0 },
        stages: [{ key: 'draft', reached: true }, { key: 'live', reached: false }],
      }],
    },
    3: { user_id: 3, state: 'not_started', articles: [], exercises: [] },
  };
  const summary = {
    students,
    items: [item, { key: 'article', kind: 'article' }],
    summary: [
      { key: 'training-a', complete: 1, in_progress: 1, not_started: 1, overdue: 2, total: 3 },
      { key: 'article', complete: 0, in_progress: 1, not_started: 2, overdue: 0, total: 3 },
    ],
    article_funnel: {
      total: 3,
      stages: [{ key: 'assigned', reached: 1 }, { key: 'draft', reached: 1, due_date: '2026-09-12', overdue: 2 },
               { key: 'live', reached: 0 }],
    },
  };
  const renderTab = async (path = '/courses/S/T/assignments') => {
    fetchAssignmentProgress.mockImplementation((slug, key) => {
      if (!key) { return Promise.resolve(summary); }
      const rows = key === 'article' ? Object.values(articleCells) : Object.values(cellsByUser);
      return Promise.resolve({ ...summary, item_key: key, rows });
    });
    await act(async () => {
      root.render(
        <MemoryRouter initialEntries={[path]}>
          <Routes>
            <Route path="/courses/S/T/assignments/*" element={<AssignmentsTabHandler course={{ slug: 'S/T' }} />} />
          </Routes>
        </MemoryRouter>
      );
    });
  };

  test('clicking an assignment row opens its students in a drawer, and again closes it', async () => {
    await renderTab();
    const rows = container.querySelectorAll('.assignments-tab__list > tbody > tr');
    expect(rows.length).toBe(1); // the assigned article is in its own panel, not the table
    expect(container.querySelector('.drawer')).toBeNull();

    const row = rows[0];
    await act(async () => { row.click(); });
    expect(fetchAssignmentProgress).toHaveBeenCalledWith('S/T', 'training-a');
    expect(row.className).toBe('open');
    expect(container.querySelectorAll('.drawer tbody tr').length).toBe(3);
    expect(container.querySelector('.drawer a').getAttribute('href'))
      .toBe('/courses/S/T/assignments/training-a/Amy');
    expect(row.querySelector('button').getAttribute('aria-expanded')).toBe('true');

    await act(async () => { row.click(); });
    expect(container.querySelector('.drawer')).toBeNull();
  });

  test('the article panel shows how much of the class reached each stage', async () => {
    await renderTab();
    const bars = [...container.querySelectorAll('.assignments-tab__funnel-bar')];
    expect(bars.map(bar => bar.querySelector('.assignments-tab__funnel-label').textContent))
      .toEqual(['Article assigned', 'Draft sandbox', 'Live article']);
    expect(bars[1].querySelector('.assignments-tab__funnel-value').textContent).toBe('1 / 3 · 33%');
    expect(bars[1].querySelector('.assignments-tab__funnel-fill').style.width).toBe('33%');
    expect(bars[1].textContent).toContain('Overdue: 2');
    expect(container.querySelector('.assignments-tab__article-roster')).toBeNull();
  });

  test('clicking a stage lists the students who haven\'t reached it, and All clears that', async () => {
    await renderTab();
    const draftBar = container.querySelectorAll('.assignments-tab__funnel-bar')[1];
    await act(async () => { draftBar.click(); });
    expect(fetchAssignmentProgress).toHaveBeenCalledWith('S/T', 'article');
    expect(draftBar.getAttribute('aria-pressed')).toBe('true');
    const names = () => [...container.querySelectorAll('.assignments-tab__student-cell a')]
      .map(a => a.textContent);
    expect(names()).toEqual(['Amy', 'Cy']);
    expect(container.querySelector('.assignments-tab__student-cell a').getAttribute('href'))
      .toBe('/courses/S/T/assignments/article/Amy?missing=draft');

    const all = [...container.querySelectorAll('.assignments-tab__article-panel button')]
      .find(button => button.textContent === 'All');
    await act(async () => { all.click(); });
    expect(names()).toEqual(['Amy', 'Bo Real (Bo)', 'Cy']);
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
          stats: { characters: 0, references: 0, revisions: 0 },
          assigned_at: '2026-09-02T15:00:00Z',
          stages: [{ key: 'bibliography', reached: true }, { key: 'live', reached: false }],
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
    expect(detail.textContent).toContain('Assigned Sep 2, 2026');
    expect([...detail.querySelectorAll('.assignments-tab__stages li')].map(li => li.className))
      .toEqual(['reached', '']);
    expect(detail.querySelectorAll('.assignments-tab__exercises li').length).toBe(2);
    expect(detail.querySelector('.assignments-tab__exercises').textContent).toContain('Overdue');

    const toggle = detail.querySelector('.assignments-tab__pages button');
    await act(async () => { toggle.click(); });
    expect(global.fetch.mock.calls[0][0]).toContain('page=User%3AAmy%2FTelomere%2FBibliography');
    expect(detail.querySelector('.assignments-tab__preview-content a').getAttribute('href'))
      .toBe('https://en.wikipedia.org/wiki/Book');
    expect(toggle.getAttribute('aria-expanded')).toBe('true');
  });

  test('the article drawer gives each article its own row, with stages, work links and assigned date', () => {
    const article = (id, title, extra = {}) => ({
      assignment_id: id, title, url: `https://en.wikipedia.org/wiki/${title}`, live: false,
      pages: [{ kind: 'draft', url: `https://en.wikipedia.org/wiki/User:Bo/${title}`, created: false }],
      stats: { characters: 0, references: 0, revisions: 0 },
      stages: [{ key: 'draft', reached: false }, { key: 'live', reached: false }],
      ...extra,
    });
    const cells = {
      1: { user_id: 1, state: 'not_started', articles: [], exercises: [] },
      2: {
        user_id: 2, state: 'in_progress', exercises: [{ slug: 'x', name: 'X', completed: true }],
        articles: [article(1, 'Telomere', { assigned_at: '2026-09-02T15:00:00Z' }), article(2, 'Heterosis')],
      },
    };
    const roster = <ArticleRoster students={students.slice(0, 2)} cellsByUser={cells} studentPath={s => `/g/${s.username}`} />;
    render('/', roster, '/');
    const rows = container.querySelectorAll('tbody tr');
    expect(rows.length).toBe(3);
    expect(rows[0].textContent).toContain('No article chosen yet');
    expect(rows[1].querySelector('td').getAttribute('rowspan')).toBe('2');
    expect(rows[1].textContent).toContain('Exercises: 1 / 1');
    expect(rows[1].textContent).toContain('Sep 2, 2026');
    expect(rows[2].querySelectorAll('td').length).toBe(4);
    expect(rows[2].querySelector('.assignments-tab__work-links a').className).toBe('assignments-tab__missing');
  });
});
