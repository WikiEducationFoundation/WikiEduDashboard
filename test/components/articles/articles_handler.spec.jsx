import '../../testHelper';

import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
import sinon from 'sinon';

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

  it('fires sort uiaction when select changes', () => {
    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <ArticlesHandler course={{ home_wiki: {} }} store={reduxStore} current_user={{}} />
      </div>
    );

    const spy = sinon.spy();

    ArticlesHandler.__Rewire__('UIActions', {
      sort: spy
    });

    const select = TestDom.querySelector('select');
    Simulate.change(select, { target: { value: 'title' } });
    expect(spy.calledWith('articles', 'title')).to.eq(true);

    ArticlesHandler.__ResetDependency__('UIActions');
  });
});
