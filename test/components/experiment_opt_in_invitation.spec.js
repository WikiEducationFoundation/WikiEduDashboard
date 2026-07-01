import '../testHelper';

// jsdom test env lacks TextEncoder/TextDecoder which react-dom needs
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');

jest.mock('../../app/assets/javascripts/utils/request');
const request = require('../../app/assets/javascripts/utils/request').default;

const ExperimentOptInInvitation = require('../../app/assets/javascripts/components/overview/experiment_opt_in_invitation').default;

const eligibleCourse = { id: 1, eligible_for_active_research_experiment: true };
const student = { isStudent: true };

const flush = async () => {
  for (let i = 0; i < 5; i += 1) {
    await act(async () => { await Promise.resolve(); });
  }
};

const renderComponent = async (course, current_user) => {
  const container = document.createElement('div');
  document.body.appendChild(container);
  await act(async () => {
    createRoot(container).render(
      React.createElement(ExperimentOptInInvitation, { course, current_user })
    );
  });
  await flush();
  return container;
};

describe('ExperimentOptInInvitation', () => {
  afterEach(() => jest.clearAllMocks());

  it('renders nothing and does not fetch for a non-student', async () => {
    const container = await renderComponent(eligibleCourse, { isStudent: false });
    expect(request).not.toHaveBeenCalled();
    expect(container.querySelector('.experiment-opt-in__panel')).toBeNull();
  });

  it('renders nothing for a course not eligible for the experiment', async () => {
    const course = { id: 1, eligible_for_active_research_experiment: false };
    const container = await renderComponent(course, student);
    expect(request).not.toHaveBeenCalled();
    expect(container.querySelector('.experiment-opt-in__panel')).toBeNull();
  });

  it('shows the opt-in modal with the message, consent form and choices', async () => {
    request.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({
        experiment_slug: 'fall_2026_research',
        needs_response: true,
        copy: {
          title: 'Research study',
          message: 'Join the **study**.',
          consent_form: 'The full consent form.',
          opt_in: 'Yes',
          opt_out: 'No'
        }
      })
    });
    const container = await renderComponent(eligibleCourse, student);
    expect(request).toHaveBeenCalledWith('/experiments/courses/1/invitation');
    expect(container.querySelector('.experiment-opt-in__panel')).not.toBeNull();
    expect(container.querySelector('.experiment-opt-in__consent').textContent).toContain('consent form');
    expect(container.querySelectorAll('.experiment-opt-in__actions button').length).toEqual(2);
  });

  it('stays hidden when the student has already responded', async () => {
    request.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ experiment_slug: 'fall_2026_research', needs_response: false })
    });
    const container = await renderComponent(eligibleCourse, student);
    expect(container.querySelector('.experiment-opt-in__panel')).toBeNull();
  });
});
