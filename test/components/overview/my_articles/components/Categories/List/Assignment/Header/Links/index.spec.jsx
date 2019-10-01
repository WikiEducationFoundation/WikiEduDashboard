import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Links from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Links';

describe('Links', () => {
  const props = {
    articleTitle: 'title',
    assignment: { id: 1, article_url: 'url' },
    current_user: { id: 99 }
  };

  it('should show the default links', () => {
    const component = shallow(<Links {...props} />);

    expect(component.find('BibliographyLink').length).toEqual(1);
    expect(component.find('SandboxLink').length).toEqual(1);
    expect(component.find('a[href="url"]').length).toEqual(1);
  });

  it('should show the peer review link if the assignment role is set to reviewing', () => {
    const newProps = { ...props, assignment: { ...props.assignment, role: 1 } };
    const component = shallow(<Links {...newProps} />);
    expect(component.find('PeerReviewLink').length).toEqual(1);
  });

  it('should show EditorLink and ReviewerLink if there are editors or reviewers', () => {
    const assignment = {
      ...props.assignment,
      editors: ['editor'],
      reviewers: ['reviewer']
    };
    const component = shallow(<Links {...props} assignment={assignment} />);
    expect(component.find('EditorLink').length).toEqual(1);
    expect(component.find('ReviewerLink').length).toEqual(1);
  });
});
