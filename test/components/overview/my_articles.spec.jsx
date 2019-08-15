import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import { MyArticles } from '../../../app/assets/javascripts/components/overview/my_articles/my_articles.jsx';

describe('MyArticles', () => {
  it('renders the My Articles header', () => {
    const props = {
      course: {},
      courseId: 'institution/title_(term)',
      current_user: { id: 1, admin: false, role: 0 },
      assignments: []
    };
    const component = shallow(<MyArticles {...props} />);
    expect(component.find('h3').text()).to.eq('My Articles');
  });
});
