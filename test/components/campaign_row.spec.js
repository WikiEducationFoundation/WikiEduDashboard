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

const CampaignRow = require('../../app/assets/javascripts/components/campaign/campaign_row').default;
const downloadActions = require('../../app/assets/javascripts/actions/download_actions');
const notificationActions = require('../../app/assets/javascripts/actions/notification_actions');

const mockStore = configureMockStore([thunk]);

describe('CampaignRow / CampaignExportModal', () => {
  let store;
  let container;

  const campaign = {
    title: 'Test Campaign',
    slug: 'test-campaign',
    human_course_count: 5,
    human_new_article_count: 10,
    human_article_count: 20,
    human_word_count: '1.5K',
    human_references_count: 50,
    human_view_sum: '100K',
    user_count: 30,
    creation_date: '2026-01-01'
  };

  beforeEach(() => {
    store = mockStore({});
    container = document.createElement('div');
    document.body.appendChild(container);
    global.Features = { user_signed_in: true, wikiEd: false };
    jest.clearAllMocks();
  });

  afterEach(() => {
    if (container && container.parentNode) {
      document.body.removeChild(container);
    }
  });

  const renderComponent = () => {
    act(() => {
      createRoot(container).render(
        React.createElement(
          Provider,
          { store },
          React.createElement('table', null,
            React.createElement('tbody', null,
              React.createElement(CampaignRow, { campaign })
            )
          )
        )
      );
    });
  };

  describe('when user is signed in', () => {
    beforeEach(() => {
      global.Features = { user_signed_in: true };
    });

    test('renders Export button that opens modal with button options', () => {
      renderComponent();
      const exportButton = container.querySelector('.campaign-export-button');
      expect(exportButton).not.toBeNull();

      act(() => {
        exportButton.click();
      });

      const modal = container.querySelector('.campaign-export-modal');
      expect(modal).not.toBeNull();

      const buttons = modal.querySelectorAll('button.button.dark.button--block');
      expect(buttons.length).toBe(6);

      buttons.forEach((btn) => {
        expect(btn.getAttribute('href')).toBeNull();
      });
    });

    test('clicking an export button dispatches startDownload with onGenerating toast', () => {
      let passedOptions;
      const startDownloadSpy = jest.spyOn(downloadActions, 'startDownload').mockImplementation((options) => {
        passedOptions = options;
        return { type: 'START_DOWNLOAD' };
      });
      const addNotificationSpy = jest.spyOn(notificationActions, 'addNotification').mockReturnValue({ type: 'ADD_NOTIFICATION' });

      renderComponent();
      act(() => {
        container.querySelector('.campaign-export-button').click();
      });

      const buttons = container.querySelectorAll('button.button.dark.button--block');
      act(() => {
        buttons[0].click();
      });

      expect(startDownloadSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'test-campaign-students',
          href: '/campaigns/test-campaign/students.csv',
          label: `Test Campaign — ${I18n.t('campaign.students_small')}`
        })
      );

      // Verify onGenerating callback
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

      // Modal closes
      expect(container.querySelector('.campaign-export-modal')).toBeNull();

      startDownloadSpy.mockRestore();
      addNotificationSpy.mockRestore();
    });
  });

  describe('when user is signed out', () => {
    beforeEach(() => {
      global.Features = { user_signed_in: false };
    });

    test('renders anchor links with hrefs for signed-out users', () => {
      renderComponent();
      act(() => {
        container.querySelector('.campaign-export-button').click();
      });

      const modal = container.querySelector('.campaign-export-modal');
      expect(modal).not.toBeNull();

      const links = modal.querySelectorAll('a.button.dark.button--block');
      expect(links.length).toBe(6);

      expect(links[0].getAttribute('href')).toBe('/campaigns/test-campaign/students.csv');
      expect(links[3].getAttribute('href')).toBe('/campaigns/test-campaign/courses.csv');
    });
  });

  test('closes modal on Escape key', () => {
    renderComponent();
    act(() => {
      container.querySelector('.campaign-export-button').click();
    });
    expect(container.querySelector('.campaign-export-modal')).not.toBeNull();

    act(() => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    });
    expect(container.querySelector('.campaign-export-modal')).toBeNull();
  });
});
