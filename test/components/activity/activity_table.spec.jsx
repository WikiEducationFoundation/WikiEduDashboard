import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import ActivityTable from '../../../app/assets/javascripts/components/activity/activity_table.jsx';
import { click } from '../../customUtils.js';

describe('ActivityTable', () => {
  const activities = [{
    key: 2,
    article_url: 'articleUrl2',
    diff_url: 'diffUrl2',
    report_url: 'reportUrl2',
    title: 'title2',
    username: 'username2',
    datetime: new Date().toISOString(),
    courses: [{
      slug: 'courseSlug2',
      title: 'courseTitle2'
    }]
  }, {
    key: 1,
    article_url: 'articleUrl',
    diff_url: 'diffUrl',
    report_url: 'reportUrl',
    title: 'title',
    username: 'username',
    datetime: new Date().toISOString(),
    courses: [{
      slug: 'courseSlug',
      title: 'courseTitle'
    }]
  }];

  const headers = [
    { title: 'Article Title', key: 'title' },
    { title: 'Revision Score', key: 'revision_score' },
    { title: 'Revision Author', key: 'username' },
    { title: 'Revision Date/Time', key: 'revision_datetime' },
  ];

  it('shows loading when loading attribute is true', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <ActivityTable
          store={reduxStore}
          loading={true}
        />
      </div>
    );

    const loading = TestTable.querySelector('.loading');
    expect(loading).to.exist;
  });

  it('renders headers', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <ActivityTable
          store={reduxStore}
          loading={false}
          activity={activities}
          headers={headers}
        />
      </div>
    );

    const headerElements = TestTable.querySelectorAll('th');
    expect(headerElements.length).to.eq(5);
  });

  it('renders activities', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <ActivityTable
          store={reduxStore}
          loading={false}
          activity={activities}
          headers={headers}
        />
      </div>
    );

    const rowElements = TestTable.querySelectorAll('tbody tr');
    expect(rowElements.length).to.eq(6);
  });

  it('renders no-activity message when no activities exist', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <ActivityTable
          store={reduxStore}
          loading={false}
          activity={[]}
          headers={headers}
          noActivityMessage={'No activity'}
        />
      </div>
    );

    const firstRow = TestTable.querySelector('tbody tr:first-child');
    expect(firstRow.textContent).to.eq('No activity');
  });

  it('can sort activities', (done) => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <ActivityTable
          store={reduxStore}
          loading={false}
          activity={activities}
          headers={headers}
        />
      </div>
    );

    expect(TestTable.querySelector('tbody tr:first-child td:first-child').textContent).to.eq('title2');
    click(TestTable.querySelector('thead tr:first-child th:first-child')).then(() => {
      expect(TestTable.querySelector('tbody tr:first-child td:first-child').textContent).to.eq('title');
      done();
    });
  });
});
