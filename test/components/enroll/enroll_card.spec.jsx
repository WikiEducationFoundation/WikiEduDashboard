import React from 'react';
import { mount } from 'enzyme';
import '../../testHelper';
import EnrollCard from '../../../app/assets/javascripts/components/enroll/enroll_card.jsx';

describe('EnrollCard', () => {
  it('Warns about ended course', () => {
    const TestEnrollCard = mount(
      <EnrollCard
        course={{ ended: true }}
      />
    );
    const h1 = TestEnrollCard.find('h1');
    expect(h1.first().text()).to.eq('The course has ended.');
  });
});
