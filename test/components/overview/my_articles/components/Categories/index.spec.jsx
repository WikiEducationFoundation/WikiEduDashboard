import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../testHelper';

import Categories from '@components/overview/my_articles/components/Categories/Categories';

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
    expect(component).toMatchSnapshot();
  });

  it('should show articles the user is improving', () => {
    const creatingProps = {
      ...props,
      assignments: [
        { article_status: 'improving_article' }
      ]
    };
    const component = shallow(<Categories {...creatingProps} />);
    expect(component).toMatchSnapshot();
  });

  it('should show articles the user is reviewing', () => {
    const creatingProps = {
      ...props,
      assignments: [
        { article_status: 'reviewing_article' }
      ]
    };
    const component = shallow(<Categories {...creatingProps} />);
    expect(component).toMatchSnapshot();
  });
});
