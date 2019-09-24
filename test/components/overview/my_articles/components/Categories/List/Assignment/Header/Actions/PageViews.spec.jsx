import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import PageViews from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/PageViews';

describe('PageViews', () => {
  it('should show a link that includes details about the article', () => {
    const props = {
      article: { language: 'language', project: 'project', title: 'title' }
    };
    const component = shallow(<PageViews {...props} />);
    const link = component.find('a');
    const href = link.props().href;
    expect(href).to.include('language');
    expect(href).to.include('project');
    expect(href).to.include('title');
  });
});
