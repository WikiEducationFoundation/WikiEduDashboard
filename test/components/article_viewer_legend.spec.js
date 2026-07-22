import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

// Ensure translations exist in test environment
if (typeof I18n !== 'undefined') {
  I18n.translations = I18n.translations || {};
  I18n.translations.en = I18n.translations.en || {};
  I18n.translations.en.users = I18n.translations.en.users || {};
  I18n.translations.en.users.scroll_to_users_edits = 'Scroll to Next Edit by %{username}';
  I18n.translations.en.users.view_user_talk_page = "View %{username}'s talk page";
}

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { Provider } = require('react-redux');
const { createStore, applyMiddleware } = require('redux');
const thunk = require('redux-thunk').default;
const Scroll = require('react-scroll');
const reducer = require('../../app/assets/javascripts/reducers').default;
const ArticleViewerLegend = require('../../app/assets/javascripts/components/common/ArticleViewer/authorship/ArticleViewerLegend').default;

const article = {
  language: 'en',
  project: 'wikipedia',
  title: 'Test Article'
};

const mockUsers = [
  {
    name: 'TestEditor1',
    userid: 1,
    activeRevision: true
  },
  {
    name: 'TestEditor2',
    userid: 2,
    activeRevision: false
  }
];

const renderComponent = (props = {}) => {
  const store = createStore(reducer, applyMiddleware(thunk));
  const container = document.createElement('div');
  document.body.appendChild(container);

  const defaultProps = {
    article,
    users: mockUsers,
    colors: ['user-highlight-1', 'user-highlight-2'],
    status: 'ready',
    failureMessage: null,
    unhighlightedContributors: []
  };

  act(() => {
    createRoot(container).render(
      React.createElement(Provider, { store },
        React.createElement(ArticleViewerLegend, { ...defaultProps, ...props }))
    );
  });
  return container;
};

describe('ArticleViewerLegend', () => {
  test('renders button for active revision editors with localized aria-label', () => {
    const container = renderComponent();
    const button = container.querySelector('.article-viewer-legend-button');
    expect(button).not.toBeNull();
    expect(button.getAttribute('aria-label')).toBe('Scroll to Next Edit by TestEditor1');
  });

  test('renders localized aria-label for user talk page links', () => {
    const container = renderComponent();
    const talkLink = container.querySelector('.user-legend-talk-link');
    expect(talkLink).not.toBeNull();
    expect(talkLink.getAttribute('aria-label')).toBe("View TestEditor1's talk page");
  });

  test('scopes user-legend-name class to active revisions', () => {
    const container = renderComponent();
    const legendNodes = container.querySelectorAll('.article-viewer-legend');

    // First user is active editor -> should have user-legend-name
    const activeLegend = Array.from(legendNodes).find(node => node.textContent.includes('TestEditor1'));
    expect(activeLegend.classList.contains('user-legend-name')).toBe(true);

    // Second user is inactive editor -> should NOT have user-legend-name
    const inactiveLegend = Array.from(legendNodes).find(node => node.textContent.includes('TestEditor2'));
    expect(inactiveLegend.classList.contains('user-legend-name')).toBe(false);
  });

  test('handles empty users array safely without crashing', () => {
    expect(() => {
      const container = renderComponent({ users: [] });
      expect(container.innerHTML).toContain('Edits by');
    }).not.toThrow();
  });

  test('focuses target with preventScroll: true when scroll button is clicked', () => {
    // Mock react-scroll scroller.scrollTo to avoid JSDOM layout calculation errors
    jest.spyOn(Scroll.scroller, 'scrollTo').mockImplementation(() => {});

    // Setup mock scrollbox container and target paragraph containing user token in DOM
    const scrollBox = document.createElement('div');
    scrollBox.id = 'article-scrollbox-id';

    const targetParagraph = document.createElement('p');
    targetParagraph.id = 'section-1';
    targetParagraph.focus = jest.fn();

    const editorToken = document.createElement('span');
    editorToken.className = 'token-editor-1';
    targetParagraph.appendChild(editorToken);

    scrollBox.appendChild(targetParagraph);
    document.body.appendChild(scrollBox);

    const container = renderComponent();
    const button = container.querySelector('.article-viewer-legend-button');

    act(() => {
      button.click();
    });

    expect(targetParagraph.focus).toHaveBeenCalledWith({ preventScroll: true });

    // Cleanup
    document.body.removeChild(scrollBox);
    Scroll.scroller.scrollTo.mockRestore();
  });
});
