import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Actions from '@components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/Actions.jsx';

describe('Actions', () => {
  const props = {
    article: {},
    assignment: {},
    courseSlug: 'course/slug',
    current_user: {},
    isComplete: false,
    username: 'username',
    isClassroomProgram: true,
    isEnglishWikipedia: jest.fn(),
    handleUpdateAssignment: jest.fn(),
    refreshAssignments: jest.fn(),
    unassign: jest.fn(),
  };

  it('shows the default buttons', () => {
    const component = shallow(<Actions {...props} />);
    expect(component.find('RemoveButton').length).toEqual(1);
    expect(component.find('PageViews').length).toEqual(0);
    expect(component.find('MarkAsIncompleteButton').length).toEqual(0);
    expect(component.find('PeerReviewChecklist').length).toEqual(0);
    expect(component.find('Connect(OnClickOutside(Feedback))').length).toEqual(0);
    expect(component.find('OnClickOutside(MainspaceChecklist)').length).toEqual(0);
    expect(component.find('OnClickOutside(FinalArticleChecklist)').length).toEqual(0);
  });

  it('should show the PageViews component if there is an article_id', () => {
    const component = shallow(<Actions {...props} assignment={{ article_id: 1 }} />);
    expect(component.find('PageViews').length).toEqual(1);
  });

  it('should show the PageViews and MarkAsIncomplete button if the assignment is complete', () => {
    const component = shallow(<Actions {...props} isComplete={true} />);
    expect(component.find('PageViews').length).toEqual(1);
    expect(component.find('MarkAsIncompleteButton').length).toEqual(1);
  });

  describe('isEnglishWikipedia() returns true', () => {
    it('should show the PeerReviewChecklist', () => {
      const component = shallow(
        <Actions {...props} isEnglishWikipedia={jest.fn().mockReturnValue(true)} />
      );
      expect(component.find('PeerReviewChecklist').length).toEqual(1);
    });

    it('should show the Feedback and MainspaceChecklist if the role is set to 0', () => {
      const component = shallow(
        <Actions
          {...props}
          assignment={{ role: 0 }}
          isEnglishWikipedia={jest.fn().mockReturnValue(true)}
        />
      );

      expect(component.find('Connect(OnClickOutside(Feedback))').length).toEqual(1);
      expect(component.find('OnClickOutside(MainspaceChecklist)').length).toEqual(1);
    });

    it('should show the Feedback and FinalArticleChecklist if the role is 0 and the article_id is set', () => {
      const component = shallow(
        <Actions
          {...props}
          assignment={{ role: 0, article_id: 99 }}
          isEnglishWikipedia={jest.fn().mockReturnValue(true)}
        />
      );

      expect(component.find('Connect(OnClickOutside(Feedback))').length).toEqual(1);
      expect(component.find('OnClickOutside(FinalArticleChecklist)').length).toEqual(1);
    });
  });
});
