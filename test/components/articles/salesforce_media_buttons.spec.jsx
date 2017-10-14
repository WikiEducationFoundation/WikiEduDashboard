import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import SalesforceMediaButtons from '../../../app/assets/javascripts/components/articles/salesforce_media_buttons.jsx';

const course = {
  id: 5,
  home_wiki: { language: 'en', project: 'wikipedia' }
};
const editors = ['Ragesoss', 'Ragesock', 'Sage (Wiki Ed)'];
const article = { id: 1234 };

describe('SalesforceMediaButtons', () => {
  it('renders a link for each editor', () => {
    const TestButtons = ReactTestUtils.renderIntoDocument(
      <div>
        <SalesforceMediaButtons
          course={course}
          article={article}
          editors={editors}
          before_rev_id={123}
          after_rev_id={234}
        />
      </div>
    );
    expect(TestButtons.querySelectorAll('a').length).to.eq(3);
  });
});
