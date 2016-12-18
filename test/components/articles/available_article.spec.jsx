import '../../testHelper';

import React from 'react';

import sinon from 'sinon';

import AvailableArticle from '../../../app/assets/javascripts/components/articles/available_article.jsx';
import NotificationActions from '../../../app/assets/javascripts/actions/notification_actions.js';

describe('AvailableArticle', () => {
  const props = {
    course: { home_wiki: { language: 'en', project: 'wikipedia' } },
    assignment: { article_title: 'two' },
    current_user: { role: 0 } // student role
  };

  it('renders', () => {
    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <AvailableArticle {...props} />
      </div>
    );
    expect(TestDom.querySelector('.assignment')).to.exist;
    expect(TestDom.textContent).to.contain('two');
  });

  it('notify when selec an article', () => {
    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <AvailableArticle {...props} />
      </div>
    );

    const spy = sinon.spy(NotificationActions, 'addNotification');

    const select = TestDom.querySelector('button');
    ReactTestUtils.Simulate.click(select);

    expect(spy.callCount).to.eq(1);
  });
});
