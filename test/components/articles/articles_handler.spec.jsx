import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import { ArticlesHandler } from '~/app/assets/javascripts/components/articles/articles_handler.jsx';

describe('ArticlesHandler', () => {
  it('renders', () => {
    const props = {
      assignments: [],
      current_user: { admin: true },
      course: {
        school: 'My School',
        home_wiki: {
          id: 1,
          language: 'en',
          project: 'wikipedia'
        }
      },
      location: { search: '' },
      wikis: []
    };
    const component = shallow(
      <ArticlesHandler {...props} />
    );

    component.setState({ loading: false });
    expect(component.find('NavLink')).toExist;
    expect(component.find('div.articles-view')).toExist;
  });
});
