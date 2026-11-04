import '../testHelper';
import { persistTimeline } from '../../app/assets/javascripts/actions/timeline_actions.js';
import * as requestModule from '../../app/assets/javascripts/utils/request';

const jsonResponse = body => ({ status: 200, ok: true, json: sinon.fake.resolves(body) });

describe('TimelineActions', () => {
  beforeEach(() => {
    sinon.stub(requestModule, 'default').callsFake((url) => {
      if (url.includes('/timeline')) { return Promise.resolve(jsonResponse({ course: { weeks: [] } })); }
      return Promise.resolve(jsonResponse({
        course: { title: 'Reloaded', missing_expected_modules: [['Plagiarism']] }
      }));
    });
  });
  afterEach(() => {
    requestModule.default.restore();
  });

  test('.persistTimeline reloads the course after a successful save', async () => {
    await persistTimeline({ weeks: [] }, 'School/Course')(reduxStore.dispatch);
    const course = reduxStore.getState().course;
    expect(course.title).toBe('Reloaded');
    expect(course.missing_expected_modules).toEqual([['Plagiarism']]);
  });
});
