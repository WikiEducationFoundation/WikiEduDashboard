
import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import { ArticlesHandler } from '~/app/assets/javascripts/components/articles/articles_handler.jsx';
import { MemoryRouter } from 'react-router-dom';

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
      <MemoryRouter>
        <ArticlesHandler {...props} />
      </MemoryRouter>
    );

    expect(component.find('NavLink')).toExist;
    expect(component.find('div.articles-view')).toExist;
  });
});
