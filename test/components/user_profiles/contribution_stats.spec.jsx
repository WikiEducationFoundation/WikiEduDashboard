import React from 'react';
import sinon from 'sinon';
import { mount } from 'enzyme';
import { expect } from 'chai';
import ContributionStats from '../../../app/assets/javascripts/components/user_profiles/contribution_stats.jsx';
import InstructorStats from '../../../app/assets/javascripts/components/user_profiles/contribution_stats.jsx';
import StudentStats from '../../../app/assets/javascripts/components/user_profiles/contribution_stats.jsx';
import '../../testHelper';

describe('ContributionStats', () => {
    const props = {
            params: { username: "nol" },
    };
    it('calls componentDidMount', () => {
        sinon.spy(ContributionStats.prototype, 'componentDidMount');
        mount(<ContributionStats {...props} store={reduxStore} />);
        expect(ContributionStats.prototype.componentDidMount).to.have.property('callCount', 1);
        ContributionStats.prototype.componentDidMount.restore();
    });
    it('allows us to set props', () => {
        const wrapper = mount(<ContributionStats {...props} store={reduxStore} />);
        expect(wrapper.props().params.username).to.equal('nol');
        wrapper.setProps({ params: { username: 'mei' } });
        expect(wrapper.props().params.username).to.equal('mei');
    });
    it('displays loading while loading', () => {
        const wrapper = mount(<ContributionStats {...props} store={reduxStore} />);
        wrapper.setProps({ isLoading: true });
        expect(wrapper.text()).to.contain('Loading');
    });
    it('renders content for instructor if user is instructor', () => {
        const wrapper = mount(<ContributionStats {...props} store={reduxStore} />);
        wrapper.setState({ isInstructor: { instructor: true } });
        wrapper.setState({ isStudent: { student: false } });
        expect(wrapper.find(InstructorStats)).to.have.length(1);
        expect(wrapper.find(StudentStats)).to.have.length(0);
    });
    it('renders content for student if user is student', () => {
        const wrapper = mount(<ContributionStats {...props} store={reduxStore} />);
        wrapper.setState({ isStudent: { student: true } });
        wrapper.setState({ isInstructor: { instructor: false } });
        expect(wrapper.find(StudentStats)).to.have.length(1);
        expect(wrapper.find(InstructorStats)).to.have.length(0);
    });
});
