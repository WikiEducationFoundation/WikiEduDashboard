import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const AssignmentLinks = require('../../app/assets/javascripts/components/common/AssignmentLinks/AssignmentLinks').default;

const user = { id: 1, username: 'Student' };

const assignmentWith = attrs => ({
  id: 1,
  role: 0,
  article_title: 'Zodiac Fresco',
  article_url: 'https://en.wikipedia.org/wiki/Zodiac_Fresco',
  sandbox_url: 'https://en.wikipedia.org/wiki/User:Student/Zodiac_Fresco',
  article_id: null,
  draft_sandbox_status: 'does_not_exist',
  ...attrs
});

describe('AssignmentLinks', () => {
  let container;

  beforeEach(() => {
    global.Features = { wikiEd: true };
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    document.body.removeChild(container);
  });

  const renderLinks = (assignment, course) => {
    act(() => {
      createRoot(container).render(
        React.createElement(AssignmentLinks, {
          assignment, course, user, courseType: 'ClassroomProgramCourse', project: 'wikipedia'
        })
      );
    });
  };

  const linkTexts = () => Array.from(container.querySelectorAll('a')).map(a => a.textContent);

  describe('in a no_sandboxes course', () => {
    const course = { no_sandboxes: true };

    test('shows the sandbox link for an article that does not exist yet', () => {
      renderLinks(assignmentWith({ article_id: null }), course);
      expect(linkTexts()).toContain('Sandbox Draft');
    });

    test('hides the sandbox link for an existing article without a sandbox draft', () => {
      renderLinks(assignmentWith({ article_id: 123 }), course);
      expect(linkTexts()).not.toContain('Sandbox Draft');
    });

    test('shows the sandbox link for an existing article with a sandbox draft', () => {
      renderLinks(assignmentWith({ article_id: 123, draft_sandbox_status: 'exists_in_userspace' }), course);
      expect(linkTexts()).toContain('Sandbox Draft');
    });
  });

  test('shows the sandbox link for an existing article in a sandbox course', () => {
    renderLinks(assignmentWith({ article_id: 123 }), { no_sandboxes: false });
    expect(linkTexts()).toContain('Sandbox Draft');
  });
});
