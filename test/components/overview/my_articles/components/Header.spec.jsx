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

    expect(component.find('.my-articles-header').length).to.equal(1);
    expect(component.find('.my-articles-header').text()).includes('My Articles');

    expect(component.find('.controls').length).to.equal(1);

    const link = component.find('Link');
    expect(link.length).to.equal(1);
    expect(link.props().to).to.equal('/courses/course/slug/article_finder');
    expect(link.find('button').text()).includes('Find Articles');
  });
});
