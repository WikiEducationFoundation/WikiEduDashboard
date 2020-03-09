import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import { ArticleViewer } from '../../../app/assets/javascripts/components/common/article_viewer.jsx';
import '../../testHelper';

describe('ArticleViewer', () => {
  it('renders', () => {
    const article = {
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
        article={article}
        course={course}
        fetchArticleDetails={() => null}
      />
    );
    expect(TestArticleViewer).toExist;
    // const showHideButton = ReactTestUtils.findRenderedDOMComponentWithClass(TestArticleViewer, 'button');
    // Simulate.click(showHideButton); // show
    // Simulate.click(showHideButton); // hide
  });
});
