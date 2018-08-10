import React from 'react';
import { shallow, mount } from 'enzyme';
import { expect } from 'chai';
import StudentStats from '../../../app/assets/javascripts/components/user_profiles/student_stats.jsx';
import '../../testHelper';

describe('<StudentStats />', () => {
    let wrapper;
    it('renders username and statistics', () => {
        const stats = {
          individual_courses_count: 10,
          course_string_prefix: "",
          individual_word_count: 100,
          individual_article_views: 12,
          individual_article_count: 20,
          individual_articles_created: 19,
          individual_upload_count: 30,
          individual_upload_usage_count: 25
        }
        wrapper = mount(<StudentStats username="mery" stats={stats} />);
        expect(wrapper.find(StudentStats)).to.have.length(1);
        const userstats = wrapper.find('div').first();
        expect(userstats.hasClass('user_stats')).to.equal(true);
        const username = wrapper.find('h5');
        expect(username.text()).to.equal(' Total impact made by mery as a student ');
    });
});