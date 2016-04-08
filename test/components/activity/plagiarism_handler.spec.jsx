import '../../testHelper';

import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';
import nock from 'nock';

import PlagiarismHandler from '../../../app/assets/javascripts/components/activity/plagiarism_handler.jsx';

describe('PlagiarismHandler', () => {
  it('can toggle course scope', () => {
    const spy = sinon.spy();

    PlagiarismHandler.__Rewire__('ServerActions', {
      fetchSuspectedPlagiarism: spy
    });

    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <PlagiarismHandler />
      </div>
    );

    // called once when mounted
    expect(spy.callCount).to.eq(1);

    // Trigger checkbox change
    const cb = TestDom.querySelector('input[type=checkbox]');
    Simulate.change(cb, { target: { checked: true } });

    // Expect to have been called again with scoped set to true
    expect(spy.secondCall.calledWith({ scoped: true })).to.eq(true);

    PlagiarismHandler.__ResetDependency__('ServerActions');
  });

  it('shows report url', (done) => {
    nock('http://localhost')
      .defaultReplyHeaders({
        'Content-Type': 'application/json'
      })
      .get('/revision_analytics/suspected_plagiarism.json?scoped=false')
      .reply(200, {
        revisions: [{
          key: '2',
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
        }]
      });

    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <PlagiarismHandler />
      </div>
    );

    setTimeout(() => {
      expect(TestDom.querySelectorAll('a[href=reportUrl2]').length).to.eq(1);
      done();
    }, 100);
  });
});
