import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../testHelper';

import List from '../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List';

describe('List', () => {
  const props = {
    assignments: [{ id: 1 }, { id: 2 }],
    course: {},
    current_user: {},
    title: 'Article Title',
    wikidataLabels: {}
  };

  it('renders', () => {
    const component = shallow(<List {...props} />);
    expect(component.find('Header').length).to.equal(1);
    expect(component.find('Connect(Assignment)').length).to.equal(2);
  });
});
