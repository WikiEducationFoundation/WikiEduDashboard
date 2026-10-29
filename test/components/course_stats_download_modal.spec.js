import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { Provider } = require('react-redux');
const configureMockStore = require('redux-mock-store').default;
const thunk = require('redux-thunk').default;

const CourseStatsDownloadModal = require('../../app/assets/javascripts/components/overview/course_stats_download_modal').default;
const downloadActions = require('../../app/assets/javascripts/actions/download_actions');
const notificationActions = require('../../app/assets/javascripts/actions/notification_actions');

const mockStore = configureMockStore([thunk]);

describe('CourseStatsDownloadModal', () => {
  let store;
  let container;

  const course = {
    title: 'African Politics (Fall 2025)',
    slug: 'Boston_College/African_Politics_(Fall_2025)',
    timeslice_update_ran: true,
    home_wiki: { project: 'wikipedia', language: 'en' }
  };

  beforeEach(() => {
    store = mockStore({});
    container = document.createElement('div');
    document.body.appendChild(container);
    global.Features = { user_signed_in: true };
    jest.clearAllMocks();
  });

  afterEach(() => {
    if (container && container.parentNode) {
      document.body.removeChild(container);
    }
  });

  const renderComponent = (props = {}) => {
    act(() => {
      createRoot(container).render(
        React.createElement(
          Provider,
          { store },
          React.createElement(CourseStatsDownloadModal, {
            course,
            ...props
          })
        )
      );
    });
  };

  test('renders the Download stats button initially', () => {
    renderComponent();
    const button = container.querySelector('button');
    expect(button).not.toBeNull();
    expect(button.textContent).toBe(I18n.t('courses.download_stats_data'));
  });

  describe('when user is signed in', () => {
    beforeEach(() => {
      global.Features = { user_signed_in: true };
    });

    test('opens modal with 4 button options (no hrefs) on button click for non-wikidata course', () => {
      renderComponent();
      const openButton = container.querySelector('button');
      act(() => {
        openButton.click();
      });

      const modal = container.querySelector('.course-stats-download-modal');
      expect(modal).not.toBeNull();

      const buttons = modal.querySelectorAll('button.button.right');
      expect(buttons.length).toBe(4);

      buttons.forEach((btn) => {
        expect(btn.getAttribute('href')).toBeNull();
      });

      expect(modal.querySelectorAll('a.button.right').length).toBe(0);
    });

    test('includes wikidata option when course has wikidata stats and home_wiki is wikidata', () => {
      const wikidataCourse = {
        ...course,
        course_stats: true,
        home_wiki: { project: 'wikidata', language: 'www' }
      };
      renderComponent({ course: wikidataCourse });
      act(() => {
        container.querySelector('button').click();
      });

      const modal = container.querySelector('.course-stats-download-modal');
      const buttons = modal.querySelectorAll('button.button.right');
      expect(buttons.length).toBe(5);
    });

    test('clicking a button dispatches startDownload with onGenerating callback and closes modal', () => {
      let passedOptions;
      const startDownloadSpy = jest.spyOn(downloadActions, 'startDownload').mockImplementation((options) => {
        passedOptions = options;
        return { type: 'START_DOWNLOAD' };
      });
      const addNotificationSpy = jest.spyOn(notificationActions, 'addNotification').mockReturnValue({ type: 'ADD_NOTIFICATION' });

      renderComponent();
      act(() => {
        container.querySelector('button').click();
      });

      const buttons = container.querySelectorAll('button.button.right');
      const overviewButton = buttons[0];

      act(() => {
        overviewButton.click();
      });

      expect(startDownloadSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          id: `${course.slug}-overview`,
          href: `/course_csv?course=${course.slug}`,
          label: `${course.title} — ${I18n.t('courses.data_overview')}`
        })
      );

      expect(addNotificationSpy).not.toHaveBeenCalled();
      act(() => {
        passedOptions.onGenerating();
      });
      expect(addNotificationSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          message: I18n.t('courses.data_download_generating', {
            defaultValue: I18n.t('campaign.data_download_generating')
          }),
          closable: true,
          type: 'success'
        })
      );

      expect(container.querySelector('.course-stats-download-modal')).toBeNull();

      startDownloadSpy.mockRestore();
      addNotificationSpy.mockRestore();
    });
  });

  describe('when user is signed out', () => {
    beforeEach(() => {
      global.Features = { user_signed_in: false };
    });

    test('opens modal with plain anchor links with hrefs so visitors get the login prompt', () => {
      renderComponent();
      const openButton = container.querySelector('button');
      act(() => {
        openButton.click();
      });

      const modal = container.querySelector('.course-stats-download-modal');
      expect(modal).not.toBeNull();

      const links = modal.querySelectorAll('a.button.right');
      expect(links.length).toBe(4);

      const expectedHrefs = [
        `/course_csv?course=${course.slug}`,
        `/course_uploads_csv?course=${course.slug}`,
        `/course_students_csv?course=${course.slug}`,
        `/course_articles_csv?course=${course.slug}`
      ];

      expectedHrefs.forEach((href, index) => {
        expect(links[index].getAttribute('href')).toBe(href);
      });
    });
  });

  test('displays warning message when timeslice update has not run', () => {
    const unupdatedCourse = {
      ...course,
      timeslice_update_ran: false
    };
    renderComponent({ course: unupdatedCourse });
    act(() => {
      container.querySelector('button').click();
    });

    const warning = container.querySelector('.warning');
    expect(warning).not.toBeNull();
    expect(warning.textContent).toContain(I18n.t('courses.data_download_warning'));
  });

  test('closes modal when close button is clicked', () => {
    renderComponent();
    act(() => {
      container.querySelector('button').click();
    });
    expect(container.querySelector('.course-stats-download-modal')).not.toBeNull();

    act(() => {
      container.querySelector('.icon-close').click();
    });
    expect(container.querySelector('.course-stats-download-modal')).toBeNull();
  });

  test('closes modal when Escape key is pressed', () => {
    renderComponent();
    act(() => {
      container.querySelector('button').click();
    });
    expect(container.querySelector('.course-stats-download-modal')).not.toBeNull();

    act(() => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    });
    expect(container.querySelector('.course-stats-download-modal')).toBeNull();
  });
});
