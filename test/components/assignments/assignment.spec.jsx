import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import Assignment from '../../../app/assets/javascripts/components/assignments/assignment.jsx';

const course = {
  home_wiki: { language: 'en', project: 'wikipedia' }
};

const article = {
  title: 'Selfie',
  rating: 'c',
};

describe('Assignment', () => {
  it('renders for assigned article role', () => {
    const assignmentGroup = [
      {
        language: 'en',
        project: 'wikipedia',
        role: 0,
        user_id: 1,
        username: 'Ragesoss'
      }
    ];

    const TestAssignment = shallow(
      <Assignment article={article} assignmentGroup={assignmentGroup} course={course} />
    );

    expect(TestAssignment.text()).to.contain('Ragesoss');
    expect(TestAssignment.text()).to.contain(article.title);
  });

  it('renders for reviewing role', () => {
    const assignmentGroup = [
      {
        language: 'en',
        project: 'wikipedia',
        role: 1,
        user_id: 1,
        username: 'Ragesock'
      },
      {
        language: 'en',
        project: 'wikipedia',
        role: 1,
        user_id: 1,
        username: 'Protonk'
      }
    ];

    const TestAssignment = shallow(
      <Assignment article={article} assignmentGroup={assignmentGroup} course={course} />
    );

    expect(TestAssignment.text()).to.contain('Ragesock');
    expect(TestAssignment.text()).to.contain(article.title);
  });
});
