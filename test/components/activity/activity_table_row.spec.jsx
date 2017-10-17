import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import ActivityTableRow from '../../../app/assets/javascripts/components/activity/activity_table_row.jsx';

describe('ActivityTableRow', () => {
  const TestRow = ReactTestUtils.renderIntoDocument(
    <table>
      <tbody>
        <ActivityTableRow
          key={'23948'}
          rowId={675818536}
          title="Selfie"
          articleUrl="https://en.wikipedia.org/wiki/Selfie"
          author="Wavelength"
          talkPageLink="https://en.wikipedia.org/wiki/User_talk:Wavelength"
          diffUrl="https://en.wikipedia.org/w/index.php?title=Selfie&diff=675818536&oldid=675437996"
          revisionDateTime="2015/08/012 9:43 pm"
          revisionScore={61}
          isOpen={false}
        />
      </tbody>
    </table>
  );

  it('renders a table row with a closed class', () => {
    expect(TestRow.querySelectorAll('tr')[0].className).to.eq('closed');
  });
});
