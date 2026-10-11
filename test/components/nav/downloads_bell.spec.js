import '../../testHelper';

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { Provider } = require('react-redux');
const { configureStore } = require('@reduxjs/toolkit');

const DownloadsBell = require('../../../app/assets/javascripts/components/nav/downloads_bell').default;
const downloads = require('../../../app/assets/javascripts/reducers/downloads').default;

global.IS_REACT_ACT_ENVIRONMENT = true;

describe('DownloadsBell', () => {
  let container;
  let root;

  const readyItem = {
    id: 'campaign-students',
    label: 'Campaign — Students',
    status: 'ready',
    downloadUrl: '/system/analytics/students.csv'
  };

  const renderBell = (items) => {
    const store = configureStore({
      reducer: { downloads },
      preloadedState: { downloads: { items, unreadCount: 0 } }
    });
    act(() => {
      root.render(React.createElement(Provider, { store }, React.createElement(DownloadsBell)));
    });
  };

  beforeEach(() => {
    localStorage.clear();
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    document.body.removeChild(container);
  });

  test('renders nothing when there are no downloads', () => {
    renderBell([]);
    expect(container.querySelector('.downloads-bell')).toBeNull();
  });

  test('renders the download icon when there are downloads', () => {
    renderBell([readyItem]);
    const button = container.querySelector('.downloads-bell');
    expect(button).not.toBeNull();
    expect(button.classList).toContain('icon-download_tray');
    expect(button.classList).not.toContain('icon-notifications_bell');
  });

  test('stays open after the last download is dismissed, then hides once closed', () => {
    renderBell([readyItem]);
    act(() => container.querySelector('.downloads-bell').click());
    expect(container.querySelector('.pop--downloads.open')).not.toBeNull();

    act(() => container.querySelector('.downloads-list__dismiss').click());
    expect(container.querySelector('.pop--downloads.open')).not.toBeNull();
    expect(container.querySelector('.downloads-list__empty')).not.toBeNull();

    act(() => container.querySelector('.downloads-bell').click());
    expect(container.querySelector('.downloads-bell')).toBeNull();
  });
});
