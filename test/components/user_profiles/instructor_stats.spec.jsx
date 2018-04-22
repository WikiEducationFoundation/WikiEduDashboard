import React from 'react';
import { shallow } from 'enzyme';
import { expect } from 'chai';
import InstructorStats from '../../../app/assets/javascripts/components/user_profiles/instructor_stats.jsx';
import ByStudentsStats from '../../../app/assets/javascripts/components/user_profiles/by_students_stats.jsx';
import CoursesTaughtGraph from '../../../app/assets/javascripts/components/user_profiles/graphs/as_instructor_graphs/courses_taught_graph.jsx';
import StudentsTaughtGraph from '../../../app/assets/javascripts/components/user_profiles/graphs/as_instructor_graphs/students_taught_graph.jsx';
import StudentStats from '../../../app/assets/javascripts/components/user_profiles/student_stats.jsx';
import '../../testHelper';

describe('describe InstructorStats', () => {
    const props = {
            username: 'shin',
            stats: { by_students: {}, courses_count: 10, as_instructor: {} },
            statsGraphsData: {},
    };
    const wrapper = shallow(<InstructorStats {...props} />);
    it('renders by students stats', () => {
        expect(wrapper.find(ByStudentsStats)).to.have.length(1);
    });
    it('renders CoursesTaughtGraph when selectedGraph is courses count', () => {
        wrapper.setState({ selectedGraph: 'courses_count' });
        expect(wrapper.find(CoursesTaughtGraph)).to.have.length(1);
        expect(wrapper.find(StudentsTaughtGraph)).to.have.length(0);
    });
    it('renders StudentsTaughtGraph when selectedGraph is students count', () => {
        wrapper.setState({ selectedGraph: 'students_count' });
        expect(wrapper.find(StudentsTaughtGraph)).to.have.length(1);
        expect(wrapper.find(CoursesTaughtGraph)).to.have.length(0);
    });
    it('renders Loading when when selectedGraph is courses count and statsGraphsData is null', () => {
        wrapper.setState({ selectedGraph: 'courses_count' });
        wrapper.setProps({ statsGraphsData: null });
        expect(wrapper.text()).to.contain('Loading');
        expect(wrapper.find(CoursesTaughtGraph)).to.have.length(0);
    });
    it('renders StudentStats component when it is a student', () => {
        wrapper.setProps({ isStudent: true });
        expect(wrapper.find(StudentStats)).to.have.length(1);
    });
});
