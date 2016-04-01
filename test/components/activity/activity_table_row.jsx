import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';

import '../../testHelper';

import ActivityTableRow from '../../../app/assets/javascripts/components/activity/activity_table_row.jsx';
import ActivityTable from '../../../app/assets/javascripts/components/activity/activity_table.cjsx';
import { click } from '../../customUtils';

describe('ActivtyTableRow', () => {
  const TestRow = ReactTestUtils.renderIntoDocument(
    <ActivityTable
      loading={false}
      activity={[{ key: '1', revision_score: 0, title: 'Foobar', courses: [{ slug: 'cat' }, { slug: 'dog' }] }]}
      headers={[{ key: '1' }]}
      noActivityMessage="Hello world"
    >
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
    </ActivityTable>
  );

  it('renders a table row with activity-table-row class and closed class', () => {
    const rows = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestRow, 'tr');
    // rows[0] is header row
    expect(rows[1].className).to.eq('activity-table-row closed');
  });

  it('changes class open to class closed when state is_open', (done) => {
    const row = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestRow, 'activity-table-row')[0];
    expect(row.className).to.eq('activity-table-row closed');
    click(row).then(r => {
      expect(r.className).to.eq('activity-table-row open');
      done();
    });
  });
});
