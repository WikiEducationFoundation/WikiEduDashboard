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

  test('opens modal with all 6 download options on button click', () => {
    renderComponent();
    const button = container.querySelector('button');
    act(() => {
      button.click();
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

  test('clicking a link dispatches startDownload and addNotification, and closes modal', () => {
    const startDownloadSpy = jest.spyOn(downloadActions, 'startDownload').mockReturnValue({ type: 'START_DOWNLOAD' });
    const addNotificationSpy = jest.spyOn(notificationActions, 'addNotification').mockReturnValue({ type: 'ADD_NOTIFICATION' });

    renderComponent();
    act(() => {
      container.querySelector('button').click();
    });

    const links = container.querySelectorAll('a.button.right');
    const coursesLink = links[0];

    act(() => {
      coursesLink.click();
    });

    expect(startDownloadSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'miscellanea-courses',
        href: '/campaigns/miscellanea/courses.csv',
        label: `Miscellanea — ${I18n.t('campaign.data_courses')}`
      })
    );

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
