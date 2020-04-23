import React from 'react';
import { shallow, mount } from 'enzyme';
import '../../../../../../../../../testHelper';

import MyArticlesAssignmentLinks from '@components/overview/my_articles/components/Categories/List/Assignment/Header/MyArticlesAssignmentLinks.jsx';

describe('MyArticlesAssignmentLinks', () => {
  const props = {
    articleTitle: 'title',
    assignment: { id: 1, article_url: 'url', role: 0 },
    courseType: 'ClassroomProgramCourse',
    current_user: { id: 99, username: 'user' }
  };

  it('should show the default links', () => {
    const component = shallow(<MyArticlesAssignmentLinks {...props} />);
    expect(component).toMatchSnapshot();
  });

  it('should not show the bibliography link if the course type is anything but ClassroomProgramCourse', () => {
    const component = mount(<MyArticlesAssignmentLinks {...props} courseType="Editathon" />);
    expect(component).toMatchSnapshot();
    expect(component.find('BibliographyLink').length).toBeUndefined;
  });

  it('should show the peer review link if the assignment role is set to reviewing', () => {
    const newProps = { ...props, assignment: { ...props.assignment, role: 1 } };
    const component = mount(<MyArticlesAssignmentLinks {...newProps} />);
    expect(component.find('PeerReviewLink').length).toEqual(1);
  });

  it('should show GroupMembersLink and ReviewerLink if there are editors or reviewers', () => {
    const assignment = {
      ...props.assignment,
      editors: ['editor'],
      reviewers: ['reviewer']
    };
    const component = mount(<MyArticlesAssignmentLinks {...props} assignment={assignment} />);
    expect(component.find('GroupMembersLink').length).toEqual(1);
    expect(component.find('AllPeerReviewLinks').length).toEqual(1);
  });
});
