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

const TestComponent = ({ article, users, assignedUsers, isOpen }) => {
  const result = useAuthorshipHighlighting({
    article,
    users,
    assignedUsers,
    isOpen,
    revisionId: null,
    parsedSettle: null,
    fetchArticleDetails: jest.fn(),
    requestTitleVerification: jest.fn()
  });

  return <div id="test-hook-result">{result.legend ? 'Has Legend' : 'No Legend'}</div>;
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
});
