import React from 'react';
import { shallow } from 'enzyme';
import { expect } from 'chai';
import ByStudentsStats from '../../../app/assets/javascripts/components/user_profiles/by_students_stats.jsx';
import '../../testHelper';

describe('<ByStudentsStats />', () => {
    let wrapper;
    it('renders username and statistics', () => {
        const fakestats = {
          word_count: 100,
          view_sum: 10,
          article_count: 6,
          new_article_count: 3,
          upload_count: 7,
          uploads_in_use_count: 2,
          upload_usage_count: 4
        };
        wrapper = shallow(<ByStudentsStats username ="Ted" stats={fakestats} />);
        expect(wrapper.text()).to.contain('Ted');
        expect(wrapper.text()).to.contain(100);
        expect(wrapper.text()).to.contain(10);
        expect(wrapper.text()).to.contain(6);
        expect(wrapper.text()).to.contain(3);
        expect(wrapper.text()).to.contain(7);
        expect(wrapper.text()).to.contain(2);
        expect(wrapper.text()).to.contain(4);
    });
});
