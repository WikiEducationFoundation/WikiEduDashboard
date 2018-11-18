import React from 'react';
// import ReactTestUtils from 'react-dom/test-utils' To be enabled when react-addons-test-utils will be removed
import ReactTestUtils from 'react-addons-test-utils';
import '../../testHelper';
import { AvailableArticle } from '../../../app/assets/javascripts/components/articles/available_article.jsx';

describe('AvailableArticle', () => {
  const props = {
    course: { home_wiki: { language: 'en', project: 'wikipedia' } },
    assignment: { article_title: 'two' },
    current_user: { isStudent: true } // student role
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
    const notificationSpy = jest.fn();
    const updateAssignmentSpy = jest.fn();
    const TestDom = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <AvailableArticle
            {...props}
            addNotification={notificationSpy}
            updateAssignment={updateAssignmentSpy}
          />
        </tbody>
      </table>
    );

    const select = TestDom.querySelector('button');
    ReactTestUtils.Simulate.click(select);

    expect(notificationSpy.mock.calls.length).to.eq(1);
    expect(updateAssignmentSpy.mock.calls.length).to.eq(1);
  });
});
