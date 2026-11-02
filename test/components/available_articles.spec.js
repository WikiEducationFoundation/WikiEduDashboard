import '../testHelper';

// jsdom test env lacks TextEncoder/TextDecoder which react-dom needs
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { Provider } = require('react-redux');
const { createStore, applyMiddleware } = require('redux');
const thunk = require('redux-thunk').default;
const { MemoryRouter } = require('react-router-dom');
const reducer = require('../../app/assets/javascripts/reducers').default;
const AvailableArticles = require('../../app/assets/javascripts/components/articles/available_articles').default;

// `stop` is referenced bare in available_article.jsx (resolves to window.stop in the browser)
global.stop = () => {};
global.Features = { wikiEd: true };

const course = {
  id: 1,
  slug: 'School/Course_(Term)',
  title: 'Course',
  home_wiki: { id: 1, project: 'wikipedia', language: 'en' },
  article_scoped: false
};

// One existing (blue) and one not-yet-created (red) available article.
const assignments = [
  {
    id: 1, user_id: null, article_id: 100, role: 0, article_title: 'Existing Article',
    article_url: 'https://en.wikipedia.org/wiki/Existing_Article', article_rating: 'c', flags: { available_article: true }
  },
  {
    id: 2, user_id: null, article_id: null, role: 0, article_title: 'New Article',
    article_url: 'https://en.wikipedia.org/wiki/New_Article', article_rating: 'does_not_exist', flags: { available_article: true }
  }
];

const renderTab = (current_user, fetchAssignments, courseOverrides = {}) => {
  const store = createStore(reducer, applyMiddleware(thunk));
  const container = document.createElement('div');
  document.body.appendChild(container);
  act(() => {
    createRoot(container).render(
      React.createElement(Provider, { store },
        React.createElement(MemoryRouter, null,
          React.createElement(AvailableArticles, {
            course: { ...course, ...courseOverrides },
            course_id: course.slug,
            current_user,
            assignments,
            fetchAssignments
          })))
    );
  });
  return container;
};

describe('AvailableArticles', () => {
  test('refetches assignments on mount so newly-added articles appear without a full reload', () => {
    const fetchAssignments = jest.fn();
    renderTab({ id: 1, isStudent: false, isAdvancedRole: true, admin: true }, fetchAssignments);
    expect(fetchAssignments).toHaveBeenCalledTimes(1);
    expect(fetchAssignments).toHaveBeenCalledWith(course.slug);
  });

  test('shows the copy-from-another-course control to instructors', () => {
    const container = renderTab({ id: 1, isStudent: false, isAdvancedRole: true, isInstructor: true, admin: false }, jest.fn());
    expect(container.querySelector('#copy-available-articles-button')).not.toBeNull();
  });

  test('hides the copy-from-another-course control from students', () => {
    const container = renderTab({ id: 999, isStudent: true, isAdvancedRole: false, isInstructor: false, admin: false }, jest.fn());
    expect(container.querySelector('#copy-available-articles-button')).toBeNull();
  });

  test('renders not-yet-created (red link) available articles for a student', () => {
    const container = renderTab({ id: 999, isStudent: true, isAdvancedRole: false, admin: false }, jest.fn());
    expect(container.innerHTML).toContain('Existing Article');
    expect(container.innerHTML).toContain('New Article');
  });

  describe('when the course metadata is locked', () => {
    const admin = { id: 1, isStudent: false, isAdvancedRole: true, isInstructor: true, admin: true };
    const student = { id: 999, isStudent: true, isAdvancedRole: false, admin: false };
    // The header's "Find Articles" link. AssignButton's closed popover has its own
    // article finder link, which can't be opened without the add button.
    const findArticlesLink = '.section-header__actions > a[href$="/article_finder"]';
    const buttonsWithText = (container, text) => (
      Array.from(container.querySelectorAll('button')).filter(button => button.textContent === text)
    );

    test('shows the add, copy, find and remove controls to an admin of an unlocked course', () => {
      const container = renderTab(admin, jest.fn());
      expect(container.querySelector('.assign-button')).not.toBeNull();
      expect(container.querySelector('#copy-available-articles-button')).not.toBeNull();
      expect(container.querySelector(findArticlesLink)).not.toBeNull();
      expect(buttonsWithText(container, I18n.t('assignments.remove')).length).toBeGreaterThan(0);
    });

    test('hides the add, copy, find and remove controls, even from an admin', () => {
      const container = renderTab(admin, jest.fn(), { metadata_locked: true });
      expect(container.querySelector('.assign-button')).toBeNull();
      expect(container.querySelector('#copy-available-articles-button')).toBeNull();
      expect(container.querySelector(findArticlesLink)).toBeNull();
      expect(buttonsWithText(container, I18n.t('assignments.remove'))).toHaveLength(0);
      expect(container.innerHTML).toContain('Existing Article'); // the list is still shown
    });

    test('shows the select control to a student of an unlocked course', () => {
      const container = renderTab(student, jest.fn());
      expect(buttonsWithText(container, I18n.t('assignments.select')).length).toBeGreaterThan(0);
    });

    test('hides the select control from a student', () => {
      const container = renderTab(student, jest.fn(), { metadata_locked: true });
      expect(buttonsWithText(container, I18n.t('assignments.select'))).toHaveLength(0);
      expect(container.innerHTML).toContain('Existing Article'); // the list is still shown
    });
  });
});
