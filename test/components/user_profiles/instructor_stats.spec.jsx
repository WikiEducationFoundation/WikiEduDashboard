import React from 'react';
import sinon from 'sinon';
import { mount } from 'enzyme';
import { shallow } from 'enzyme';
import { expect } from 'chai';
import InstructorStats from '../../../app/assets/javascripts/components/user_profiles/instructor_stats.jsx';
import ByStudentsStats from '../../../app/assets/javascripts/components/user_profiles/by_students_stats.jsx';
import '../../testHelper';

describe('describe InstructorStats', () => {
    const fake_props = { 
            username: 'shin',
            stats: { by_students: {}, courses_count: 10, as_instructor: {} },
    };
    it('renders by students stats', () => {
        const wrapper = shallow(<InstructorStats {...fake_props} />);
        expect(wrapper.find(ByStudentsStats)).to.have.length(1);
    });
    
    it('renders CoursesTaughtGraph when selectedGraph is courses count', () => {
        const wrapper = shallow(<InstructorStats {...fake_props} />);
        wrapper.setProps({ stats: { selectedGraph: 'students_count' } });
    });
});