import React from 'react';
import { shallow } from 'enzyme';
import '../../../../testHelper';

import NoAssignmentMessage from '../../../../../app/assets/javascripts/components/overview/my_articles/components/NoAssignmentMessage';

describe('NoAssignmentMessage', () => {
  const component = shallow(<NoAssignmentMessage course={{ type: 'ClassroomProgramCourse' }}/>);
  it('should render', () => {
    expect(component).toMatchSnapshot();
  });
  it('should include a link on how to find an article', () => {
    expect(component.find('a').contains('How to find an article')).toBeTruthy;
  });
  it('should include a link on evaluating articles and sources', () => {
    expect(component.find('a').contains('Evaluating articles and sources')).toBeTruthy;
  });
});
