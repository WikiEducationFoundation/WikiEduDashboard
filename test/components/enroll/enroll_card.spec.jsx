import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import '../../testHelper';
import EnrollCard from '../../../app/assets/javascripts/components/enroll/enroll_card.jsx';

describe('EnrollCard', () => {

  it('Warns about ended course', () => {
    const TestEnrollCard = ReactTestUtils.renderIntoDocument(
      <EnrollCard
        user={{ id: 1 }}
        userRole={ -1 }
        course={{ title: 'title', ended: true, enroll_url: "http://localhost:3000/courses/school/title_(term)/enroll/" }}
        courseLink={ "/courses/school/title_(term)" }
        passcode={ "ouzaxlys" }
        enrolledParam={ undefined }
        enrollFailureReason={ "none" }
      />
    );
    const h1 = ReactTestUtils.findRenderedDOMComponentWithTag(TestEnrollCard, 'h1');
    expect(h1.textContent).to.eq('The course has ended.');
  });

});
