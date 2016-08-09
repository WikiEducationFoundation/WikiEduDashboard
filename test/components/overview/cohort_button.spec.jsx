import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import CohortButton from '../../../app/assets/javascripts/components/overview/cohort_button.jsx';

describe('CohortButton', () => {
  // const CohortButton = rewire('../../../app/assets/javascripts/components/overview/cohort_button.jsx');
  // const CohortStore = rewire('../../../app/assets/javascripts/stores/cohort_store.coffee');

  it('renders a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <CohortButton
        cohorts={[]}
        show={true}
      />
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
  });
});
