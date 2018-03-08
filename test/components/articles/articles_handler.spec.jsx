import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import '../../testHelper';

import ArticlesHandler from '../../../app/assets/javascripts/components/articles/articles_handler.jsx';

describe('ArticlesHandler', () => {
  it('renders', () => {
    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <ArticlesHandler course={{ home_wiki: {} }} store={reduxStore} current_user={{}} />
      </div>
    );
    expect(TestDom.querySelector('h3')).to.exist;
  });
});
