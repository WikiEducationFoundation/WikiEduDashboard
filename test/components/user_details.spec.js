import '../testHelper';
import API from '../../app/assets/javascripts/utils/api';

const React = require('react');
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;
const { createRoot } = require('react-dom/client');
const { MemoryRouter, Routes, Route } = require('react-router-dom');
const { act } = require('react-dom/test-utils');
const UserDetails = require('../../app/assets/javascripts/components/user_profiles/user_details').default;

jest.mock('../../app/assets/javascripts/utils/api', () => ({
  __esModule: true,
  default: { fetchUserArticles: jest.fn() }
}));

const article = (title, language, wordCount, newArticle) => ({
  article_id: title.length,
  title,
  url: `https://${language}.wikipedia.org/wiki/${title}`,
  word_count: wordCount,
  references_count: wordCount,
  new_article: newArticle,
  language,
  project: 'wikipedia',
  wiki_language: language
});

// Course totals come from CoursesUsers. A shared article on a legacy-path
// course has no per-user figures.
const articlesByCourse = [
  {
    course_id: 1,
    course_title: 'Group course',
    course_slug: 'Uni/Group',
    word_count: 57,
    references_count: 57,
    articles_edited: 2,
    articles: [article('Shared', 'en', null, false), article('Created', 'en', 30, true)]
  },
  {
    course_id: 2,
    course_title: 'Spanish course',
    course_slug: 'Uni/Spanish',
    word_count: 20,
    references_count: 20,
    articles_edited: 1,
    articles: [article('Solo', 'es', 20, false)]
  }
];

// Returns the header total shown for each course, keyed by course title. The
// newness filter is chosen in its select, since it is only offered once the
// articles have loaded.
const courseTotalsAt = async (search, newness) => {
  window.history.replaceState(null, '', `/users/StudentA/stats/words${search}`);
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  await act(async () => {
    root.render(
      <MemoryRouter initialEntries={['/users/StudentA/stats/words']}>
        <Routes>
          <Route path="/users/:username/stats/:metric" element={<UserDetails username="StudentA" />} />
        </Routes>
      </MemoryRouter>
    );
  });
  if (newness) {
    const select = container.querySelector('option[value="new"]').parentElement;
    act(() => {
      select.value = newness;
      select.dispatchEvent(new Event('change', { bubbles: true }));
    });
  }
  const totals = {};
  container.querySelectorAll('.user-details-course').forEach((section) => {
    const title = section.querySelector('h4').textContent;
    totals[title] = section.querySelector('.user-details-course__header strong').textContent;
  });
  act(() => root.unmount());
  container.remove();
  return totals;
};

describe('UserDetails course totals', () => {
  beforeEach(() => {
    API.fetchUserArticles.mockResolvedValue({ articles_by_course: articlesByCourse });
  });

  afterEach(() => {
    window.history.replaceState(null, '', '/');
  });

  test('shows the server totals when no filter is applied', async () => {
    expect(await courseTotalsAt('')).toEqual({ 'Group course': '57', 'Spanish course': '20' });
  });

  test('keeps the server total for a course whose articles all match the filter', async () => {
    expect(await courseTotalsAt('?wiki=en.wikipedia')).toEqual({ 'Group course': '57' });
  });

  test('sums the visible articles when the filter hides some of them', async () => {
    expect(await courseTotalsAt('', 'new')).toEqual({ 'Group course': '30' });
  });

  test('shows no total when a visible article has no figures of its own', async () => {
    expect(await courseTotalsAt('', 'existing'))
      .toEqual({ 'Group course': '-', 'Spanish course': '20' });
  });
});
