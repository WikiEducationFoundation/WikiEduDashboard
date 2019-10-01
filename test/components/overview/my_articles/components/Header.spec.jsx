import React from 'react';
import { shallow } from 'enzyme';
import '../../../../testHelper';

import Header from '../../../../../app/assets/javascripts/components/overview/my_articles/components/Header';

describe('Header', () => {
  const props = {
    assigned: [],
    course: { slug: 'course/slug' },
    current_user: {},
    reviewable: [],
    reviewing: [],
    unassigned: [],
    wikidataLabels: {},
  };
  const component = shallow(<Header {...props} />);
  it('renders the Header component', () => {
    expect(component).toMatchSnapshot();
  });
  it('includes a link to the article finder', () => {
    const link = component.find('Link');
    expect(link.length).toEqual(1);
    expect(link.props().to).toEqual('/courses/course/slug/article_finder');
    expect(link.find('button').text()).toContain('Find Articles');
  });
});
