import React from 'react';
import MyAssignment from '../../../app/assets/javascripts/components/overview/my_assignment.jsx';
import '../../testHelper';
import { shallow } from 'enzyme';
import Feedback from '../../../app/assets/javascripts/components/common/feedback.jsx';

describe('<MyAssignment />', () => {
  const assignment = { id: 1, role: 0, article_title: '1' };
  const course = { home_wiki: { language: 'en', project: 'wikipedia' } };

  it('feedback button is displayed on sandbox and improving articles', () => {
    const props = { course: course, assignment: assignment, last: false };
    // Sandbox articles
    let wrapper = shallow(<MyAssignment {...props} />);
    expect(wrapper.find(Feedback)).to.have.length(1);

    // Improving Articles
    props.assignment = { id: 1, role: 0, article_title: 'One', article_url: 'https://en.wikipedia.org/wiki/1' };
    wrapper = shallow(<MyAssignment {...props} />);
    expect(wrapper.find(Feedback)).to.have.length(1);
  });

  it('feedback button not present for non English Wikipedia', () => {
    const props = { course: course, assignment: assignment, last: false };
    props.course = { home_wiki: { language: 'en', project: 'wikivoyage' } };

    let wrapper = shallow(<MyAssignment {...props} />);
    expect(wrapper.find(Feedback)).to.have.length(0);

    props.assignment = { id: 1, role: 0, article_title: 'One', article_url: 'https://en.wikipedia.org/wiki/1' };
    wrapper = shallow(<MyAssignment {...props} />);
    expect(wrapper.find(Feedback)).to.have.length(0);
  });
});
