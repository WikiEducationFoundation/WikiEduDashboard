import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../testHelper';

import Header from '@components/overview/my_articles/components/Categories/List/Assignment/Header/Header.jsx';

describe('Header', () => {
  const props = {
    article: {
      project: 'project'
    },
    articleTitle: 'title',
    assignment: {},
    course: { slug: 'course/slug', type: 'ClassroomProgramCourse' },
    current_user: {},
    isComplete: true,
    username: 'username',
    deleteAssignment: jest.fn(),
    fetchAssignments: jest.fn(),
    initiateConfirm: jest.fn(),
    updateAssignmentStatus: jest.fn()
  };

  it('displays the links and actions', () => {
    const component = shallow(<Header {...props} />);
    expect(component).toMatchSnapshot();
  });
});
