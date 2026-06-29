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

const renderTab = (current_user, fetchAssignments) => {
  const store = createStore(reducer, applyMiddleware(thunk));
  const container = document.createElement('div');
  document.body.appendChild(container);
  act(() => {
    createRoot(container).render(
      React.createElement(Provider, { store },
        React.createElement(MemoryRouter, null,
          React.createElement(AvailableArticles, {
            course,
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

  test('renders not-yet-created (red link) available articles for a student', () => {
    const container = renderTab({ id: 999, isStudent: true, isAdvancedRole: false, admin: false }, jest.fn());
    expect(container.innerHTML).toContain('Existing Article');
    expect(container.innerHTML).toContain('New Article');
  });
});
