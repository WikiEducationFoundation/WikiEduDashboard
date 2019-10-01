import React from 'react';
import { shallow } from 'enzyme';
import '../../../../testHelper';

import Header from '../../../../../app/assets/javascripts/components/overview/my_articles/components/Header';

describe('Header', () => {
  it('renders the Header component', () => {
    const props = {
      assigned: [],
      course: { slug: 'course/slug' },
      current_user: {},
      reviewable: [],
      reviewing: [],
      unassigned: [],
      wikidataLabels: {},
    };
    const component = shallow(
      <Header {...props}/>
    );

    expect(component.find('.my-articles-header').length).toEqual(1);
    expect(component.find('.my-articles-header').text()).toContain('My Articles');

    expect(component.find('.controls').length).toEqual(1);

    const link = component.find('Link');
    expect(link.length).toEqual(1);
    expect(link.props().to).toEqual('/courses/course/slug/article_finder');
    expect(link.find('button').text()).toContain('Find Articles');
  });
});
