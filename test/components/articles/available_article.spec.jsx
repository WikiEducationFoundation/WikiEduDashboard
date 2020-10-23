import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
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
    expect(TestDom.querySelector('.assignment')).toExist;
    expect(TestDom.textContent).toContain('two');
  });

  it('claims an article when Select button is clicked', () => {
    const claimAssignmentSpy = jest.fn();
    const TestDom = ReactTestUtils.renderIntoDocument(
      <table>
        <tbody>
          <AvailableArticle
            {...props}
            selectable={true}
            claimAssignment={claimAssignmentSpy}
          />
        </tbody>
      </table>
    );

    const select = TestDom.querySelector('button');
    ReactTestUtils.Simulate.click(select);

    expect(claimAssignmentSpy.mock.calls.length).toEqual(1);
  });
});
