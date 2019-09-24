import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../testHelper';

import Categories from '../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories';

describe('Categories', () => {
  const props = {
    assignments: [],
    course: {},
    current_user: {},
    wikidataLabels: {}
  };

  it('should show articles the user is creating', () => {
    const creatingProps = {
      ...props,
      assignments: [
        { article_status: 'new_article' }
      ]
    };
    const component = shallow(<Categories {...creatingProps} />);

    const list = component.find('List');
    expect(list.props().title).to.equal('Articles I will create');
  });

  it('should show articles the user is improving', () => {
    const creatingProps = {
      ...props,
      assignments: [
        { article_status: 'improving_article' }
      ]
    };
    const component = shallow(<Categories {...creatingProps} />);

    const list = component.find('List');
    expect(list.props().title).to.equal('Articles I\'m updating');
  });

  it('should show articles the user is reviewing', () => {
    const creatingProps = {
      ...props,
      assignments: [
        { article_status: 'reviewing_article' }
      ]
    };
    const component = shallow(<Categories {...creatingProps} />);

    const list = component.find('List');
    expect(list.props().title).to.equal('Articles I\'m peer reviewing');
  });
});
