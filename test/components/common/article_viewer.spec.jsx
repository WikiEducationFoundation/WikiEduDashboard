import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';
import '../../testHelper';
import { Provider } from 'react-redux';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
describe('ArticleViewer', () => {
  const store = mockStore({
  });
  it('renders', () => {
    const article = {
      id: 99,
      title: 'Selfie',
      language: 'en',
      project: 'wikipedia',
      url: 'https://en.wikipedia.org/wiki/Selfie'
    };
    const course = {
      id: 1
    };
    const TestArticleViewer = ReactTestUtils.renderIntoDocument(
      <Provider store={store} >
        <ArticleViewer
          alertStatus={{}}
          article={article}
          course={course}
          fetchArticleDetails={() => null}
        />
      </Provider>

    );
    expect(TestArticleViewer).toExist;
  });
});
