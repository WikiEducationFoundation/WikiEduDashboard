import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';

import ActivityTableRow from '../../../app/assets/javascripts/components/activity/activity_table_row.jsx';
import { click } from '../../customUtils.js';

describe('ActivtyTableRow', () => {
  const TestRow = ReactTestUtils.renderIntoDocument(
    <table>
      <tbody>
        <ActivityTableRow
          key={'23948'}
          rowId={'675818536'}
          title="Selfie"
          articleUrl="https://en.wikipedia.org/wiki/Selfie"
          author="Wavelength"
          talkPageLink="https://en.wikipedia.org/wiki/User_talk:Wavelength"
          diffUrl="https://en.wikipedia.org/w/index.php?title=Selfie&diff=675818536&oldid=675437996"
          revisionDateTime="2015/08/012 9:43 pm"
          revisionScore={61}
        />
      </tbody>
    </table>
  );

  it('renders a table row with activity-table-row class and closed class', () => {
    expect(TestRow.querySelectorAll('tr')[0].className).to.eq('activity-table-row closed');
  });

  it('changes class open to class closed when state is_open', (done) => {
    const row = TestRow.querySelector('.activity-table-row');

    expect(row.className).to.eq('activity-table-row closed');

    click(row).then(r => {
      expect(r.className).to.eq('activity-table-row open');
      done();
    });
  });
});
