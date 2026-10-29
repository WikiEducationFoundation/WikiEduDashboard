import '../testHelper';

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
const useAuthorshipHighlighting = require('../../app/assets/javascripts/components/common/ArticleViewer/hooks/useAuthorshipHighlighting').default;

// The two authorship requests, answered by each test in the order it chooses.
const deferred = () => {
  const handlers = {};
  const promise = new Promise((resolve, reject) => {
    handlers.resolve = resolve;
    handlers.reject = reject;
  });
  return { promise, ...handlers };
};
let mockWhoColorRequest;
let mockUserIdsRequest;

jest.mock('../../app/assets/javascripts/components/common/ArticleViewer/authorship/AuthorshipAPI', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => ({
    fetchWhocolorHtml: () => mockWhoColorRequest.promise,
    fetchUserIds: () => mockUserIdsRequest.promise
  }))
}));

const TestComponent = ({ article, users, assignedUsers, isOpen, parsedSettle = null, showArticleFinder = false }) => {
  const result = useAuthorshipHighlighting({
    article,
    users,
    assignedUsers,
    showArticleFinder,
    isOpen,
    revisionId: null,
    parsedSettle,
    fetchArticleDetails: jest.fn(),
    requestTitleVerification: jest.fn()
  });

  return (
    <div id="test-hook-result">
      {result.legend ? 'Has Legend' : 'No Legend'}
      <div id="pending">{result.pending ? 'pending' : 'settled'}</div>
      <div id="html">{result.html || ''}</div>
    </div>
  );
};

describe('useAuthorshipHighlighting hook', () => {
  test('handles null users list gracefully without crashing', () => {
    const store = createStore(reducer, applyMiddleware(thunk));
    const container = document.createElement('div');
    document.body.appendChild(container);

    const article = { language: 'en', project: 'wikipedia', title: 'Test' };

    expect(() => {
      act(() => {
        createRoot(container).render(
          React.createElement(Provider, { store },
            React.createElement(TestComponent, { article, users: null, assignedUsers: null, isOpen: true }))
        );
      });
    }).not.toThrow();

    document.body.removeChild(container);
  });

  test('handles empty users list ([]) gracefully without crashing', () => {
    const store = createStore(reducer, applyMiddleware(thunk));
    const container = document.createElement('div');
    document.body.appendChild(container);

    const article = { language: 'en', project: 'wikipedia', title: 'Test' };

    expect(() => {
      act(() => {
        createRoot(container).render(
          React.createElement(Provider, { store },
            React.createElement(TestComponent, { article, users: [], assignedUsers: [], isOpen: true }))
        );
      });
    }).not.toThrow();

    document.body.removeChild(container);
  });
});

// WhoColor and the user-id lookup are two independent requests. Highlighting
// uses the ids, so it must wait for whichever answers last (#7195).
describe('useAuthorshipHighlighting hook: WhoColor and user-id ordering', () => {
  const article = { language: 'en', project: 'wikipedia', title: 'Test' };
  const users = [{ username: 'Ragesoss' }];
  const whoColorResponse = {
    html: '<span class="editor-token token-editor-123">text</span>',
    tokens: [[0, 'text', 1, 0, 0, '123', 0]]
  };
  const userIdsResponse = { query: { users: [{ userid: 123, name: 'Ragesoss' }] } };

  let container;
  let root;

  const pending = () => container.querySelector('#pending').textContent;
  const html = () => container.querySelector('#html').textContent;

  const render = async (props) => {
    const store = createStore(reducer, applyMiddleware(thunk));
    await act(async () => {
      root.render(
        React.createElement(Provider, { store },
          React.createElement(TestComponent, { article, isOpen: true, parsedSettle: { ok: true, id: 1 }, ...props }))
      );
    });
  };

  beforeEach(() => {
    mockWhoColorRequest = deferred();
    mockUserIdsRequest = deferred();
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(async () => {
    await act(async () => { root.unmount(); });
    document.body.removeChild(container);
  });

  test('waits for the user ids when WhoColor answers first', async () => {
    await render({ users });

    await act(async () => { mockWhoColorRequest.resolve(whoColorResponse); });
    expect(pending()).toEqual('pending');
    expect(html()).not.toContain('title="Ragesoss"');

    await act(async () => { mockUserIdsRequest.resolve(userIdsResponse); });
    expect(pending()).toEqual('settled');
    expect(html()).toContain('title="Ragesoss" class="editor-token token-editor-123');
  });

  test('highlights as soon as WhoColor answers when the user ids are already in', async () => {
    await render({ users });

    await act(async () => { mockUserIdsRequest.resolve(userIdsResponse); });
    expect(pending()).toEqual('pending');

    await act(async () => { mockWhoColorRequest.resolve(whoColorResponse); });
    expect(pending()).toEqual('settled');
    expect(html()).toContain('title="Ragesoss" class="editor-token token-editor-123');
  });

  test('still shows the article and clears the spinner when the user-id lookup fails', async () => {
    await render({ users });

    await act(async () => { mockWhoColorRequest.resolve(whoColorResponse); });
    expect(pending()).toEqual('pending');

    await act(async () => { mockUserIdsRequest.reject(new Error('lookup failed')); });
    expect(pending()).toEqual('settled');
    expect(html()).toContain('token-editor-123');
    expect(html()).not.toContain('title="Ragesoss"');
  });

  test('does not wait for user ids in finder mode, where none are requested', async () => {
    await render({ users: null, showArticleFinder: true });

    await act(async () => { mockWhoColorRequest.resolve(whoColorResponse); });
    expect(pending()).toEqual('settled');
    expect(html()).toContain('token-editor-123');
  });
});
