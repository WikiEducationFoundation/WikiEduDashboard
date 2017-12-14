import '../../testHelper';
import React from 'react';

import { AvailableArticle } from '../../../app/assets/javascripts/components/articles/available_article.jsx';

describe('AvailableArticle', () => {
  const props = {
    course: { home_wiki: { language: 'en', project: 'wikipedia' } },
    assignment: { article_title: 'two' },
    current_user: { role: 0 }, // student role
  };

  it('renders', () => {
    const TestDom = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <AvailableArticle
            {...props}
          />
        </tbody>
      </table>
    );
    expect(TestDom.querySelector('.assignment')).to.exist;
    expect(TestDom.textContent).to.contain('two');
  });

  it('notify when an article is selected', () => {
    const spy = jest.fn();
    const TestDom = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <AvailableArticle
            {...props}
            addNotification={spy}
          />
        </tbody>
      </table>
    );

    const select = TestDom.querySelector('button');
    ReactTestUtils.Simulate.click(select);

    expect(spy.mock.calls.length).to.eq(1);
  });
});
