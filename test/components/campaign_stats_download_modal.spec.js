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

const CampaignStatsDownloadModal = require('../../app/assets/javascripts/components/campaign/campaign_stats_download_modal').default;
const downloadActions = require('../../app/assets/javascripts/actions/download_actions');
const notificationActions = require('../../app/assets/javascripts/actions/notification_actions');

const mockStore = configureMockStore([thunk]);

describe('CampaignStatsDownloadModal', () => {
  let store;
  let container;

  const campaign = {
    title: 'Miscellanea',
    slug: 'miscellanea'
  };

  beforeEach(() => {
    store = mockStore({
      campaign
    });
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
          React.createElement(CampaignStatsDownloadModal, {
            campaign_slug: 'miscellanea',
            campaign,
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

    test('opens modal with 6 button options (no hrefs) on button click', () => {
      renderComponent();
      const openButton = container.querySelector('button');
      act(() => {
        openButton.click();
      });

      const modal = container.querySelector('.course-stats-download-modal');
      expect(modal).not.toBeNull();

      const buttons = modal.querySelectorAll('button.button.right');
      expect(buttons.length).toBe(6);

      // Buttons have no href attribute to prevent bypassing the flow via middle-click
      buttons.forEach((btn) => {
        expect(btn.getAttribute('href')).toBeNull();
      });

      expect(modal.querySelectorAll('a.button.right').length).toBe(0);
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
      const coursesButton = buttons[0];

      act(() => {
        coursesButton.click();
      });

      expect(startDownloadSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'miscellanea-courses',
          href: '/campaigns/miscellanea/courses.csv',
          label: `Miscellanea — ${I18n.t('campaign.data_courses')}`
        })
      );

      // Verify that the onGenerating callback dispatches the toast notification
      expect(addNotificationSpy).not.toHaveBeenCalled();
      act(() => {
        passedOptions.onGenerating();
      });
      expect(addNotificationSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          message: I18n.t('campaign.data_download_generating'),
          closable: true,
          type: 'success'
        })
      );

      // Modal should close
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
      expect(links.length).toBe(6);

      const expectedHrefs = [
        '/campaigns/miscellanea/courses.csv',
        '/campaigns/miscellanea/articles_csv.csv',
        '/campaigns/miscellanea/students.csv',
        '/campaigns/miscellanea/students.csv?course=true',
        '/campaigns/miscellanea/instructors.csv?course=true',
        '/campaigns/miscellanea/wikidata.csv'
      ];

      expectedHrefs.forEach((href, index) => {
        expect(links[index].getAttribute('href')).toBe(href);
      });
    });
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
