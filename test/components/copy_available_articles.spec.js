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
const reducer = require('../../app/assets/javascripts/reducers').default;
const { RECEIVE_USER_COURSES } = require('../../app/assets/javascripts/constants');
const API = require('../../app/assets/javascripts/utils/api.js').default;
const CopyAvailableArticles = require('../../app/assets/javascripts/components/articles/copy_available_articles').default;

const course = {
  id: 1,
  slug: 'School/Alpha_(Term)',
  title: 'Alpha course',
  home_wiki: { id: 1, project: 'wikipedia', language: 'en' }
};
const instructor = { id: 1, isInstructor: true, admin: false };
const userCourses = [
  { id: 1, slug: course.slug, title: 'Alpha course' },
  { id: 2, slug: 'School/Beta_(Term)', title: 'Beta course' }
];

// React only picks up programmatic value changes that go through the native setter.
const typeInto = (input, value) => {
  const setter = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(input), 'value').set;
  setter.call(input, value);
  input.dispatchEvent(new Event('input', { bubbles: true }));
};

const renderDialog = () => {
  const store = createStore(reducer, applyMiddleware(thunk));
  store.dispatch({ type: RECEIVE_USER_COURSES, payload: { data: { courses: userCourses } } });
  const container = document.createElement('div');
  document.body.appendChild(container);
  act(() => {
    createRoot(container).render(
      React.createElement(Provider, { store },
        React.createElement(CopyAvailableArticles, {
          course, course_id: course.slug, current_user: instructor
        }))
    );
  });
  act(() => { container.querySelector('#copy-available-articles-button').click(); });
  return container;
};

describe('CopyAvailableArticles', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  test('lists the user\'s other courses as sources, excluding this course', () => {
    const container = renderDialog();
    const selectInput = container.querySelector('#copy-available-articles-source-select-input');
    act(() => {
      selectInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }));
    });
    expect(container.innerHTML).toContain('Beta course');
    expect(container.innerHTML).not.toContain('Alpha course');
  });

  test('keeps the copy button disabled until a preview arrives, then enables it', async () => {
    const preview = jest.spyOn(API, 'previewCopyAvailableArticles').mockResolvedValue({
      source: { id: 2, slug: 'School/Beta_(Term)', title: 'Beta course' }, count: 3, already_present: 1
    });
    const container = renderDialog();
    const copyButton = container.querySelector('.copy-available-articles .button.dark');
    expect(copyButton.disabled).toBe(true);

    act(() => { typeInto(container.querySelector('#copy-available-articles-source-url'), 'School/Beta_(Term)'); });
    await act(async () => { jest.advanceTimersByTime(400); });

    expect(preview).toHaveBeenCalledWith({
      course_slug: course.slug, source: 'School/Beta_(Term)', include_student_assigned: false
    });
    // 3 in the source, 1 already here: 2 would be added
    expect(container.querySelector('.copy-available-articles__preview p').textContent)
      .toBe('Beta course: 2 articles');
    expect(copyButton.disabled).toBe(false);
  });

  test('shows the server message when the source cannot be used', async () => {
    const error = new Error('Not Found');
    error.responseText = JSON.stringify({ message: 'No such course' });
    jest.spyOn(API, 'previewCopyAvailableArticles').mockRejectedValue(error);
    const container = renderDialog();

    act(() => { typeInto(container.querySelector('#copy-available-articles-source-url'), 'School/Nope_(Term)'); });
    await act(async () => { jest.advanceTimersByTime(400); });

    expect(container.querySelector('.copy-available-articles__preview .red').textContent).toBe('No such course');
    expect(container.querySelector('.copy-available-articles .button.dark').disabled).toBe(true);
  });
});
