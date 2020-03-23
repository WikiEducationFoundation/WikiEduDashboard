import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import { ArticleViewer } from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';
import '../../testHelper';

describe('ArticleViewer', () => {
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
      <ArticleViewer
        alertStatus={{}}
        article={article}
        course={course}
        fetchArticleDetails={() => null}
      />
    );
    expect(TestArticleViewer).toExist;
  });
});
