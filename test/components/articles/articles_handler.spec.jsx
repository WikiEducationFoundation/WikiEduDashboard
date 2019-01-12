import React from 'react';
import { shallow } from 'enzyme';

import { ArticlesHandler } from '../../../app/assets/javascripts/components/articles/articles_handler.jsx';
import '../../testHelper';

describe('ArticlesHandler', () => {
  it('renders', () => {
    const props = {
      course: {
        school: 'My School',
        home_wiki: {
          id: 1,
          language: 'en',
          project: 'wikipedia'
        }
      },
      wikis: []
    };
    const component = shallow(
      <ArticlesHandler {...props} />
    );

    expect(component.find('h3')).to.exist;
    expect(component.text()).to.contain('Articles Edited');
  });
});
