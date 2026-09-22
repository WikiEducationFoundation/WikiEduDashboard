import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

if (typeof I18n !== 'undefined') {
  I18n.translations = I18n.translations || {};
  I18n.translations.en = I18n.translations.en || {};
  I18n.translations.en.courses = I18n.translations.en.courses || {};
  I18n.translations.en.courses.controlled_by_event_center = 'Enrollment in this event is controlled by Wikimedia Event Center. It cannot be joined from the Dashboard.';
  I18n.translations.en.courses.go_to_event_center = 'Go to Event Center to register';
}

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const EnrollCard = require('../../app/assets/javascripts/components/enroll/enroll_card').default;

describe('EnrollCard', () => {
  test('renders Event Center registration link when course has active event sync', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const mockCourse = {
      title: 'Test Synced Course',
      ended: false,
      flags: {
        event_sync: '98765'
      }
    };

    act(() => {
      createRoot(container).render(
        React.createElement(EnrollCard, {
          course: mockCourse,
          user: {},
          userRoles: {}
        })
      );
    });

    const header = container.querySelector('h1');
    expect(header.textContent).toContain('Enrollment in this event is controlled by Wikimedia Event Center.');

    const link = container.querySelector('p a');
    expect(link).not.toBeNull();
    expect(link.getAttribute('href')).toBe('https://meta.wikimedia.org/wiki/Special:EventDetails/98765');
    expect(link.getAttribute('target')).toBe('_blank');
    expect(link.textContent).toContain('Go to Event Center to register');

    document.body.removeChild(container);
  });
});
