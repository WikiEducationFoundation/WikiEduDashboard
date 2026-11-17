import '../testHelper';
import { updateCourse, persistCourse } from '../../app/assets/javascripts/actions/course_actions.js';
import * as requestModule from '../../app/assets/javascripts/utils/request';
import { PERSISTED_COURSE } from '../../app/assets/javascripts/constants';

describe('CourseActions', () => {
  beforeEach(() => {
    sinon.stub(requestModule, 'default').resolves(
      { status: 200, ok: true, json: sinon.fake.returns({ course: { title: 'Bar' } }) }
    );
  });
  afterEach(() => {
    requestModule.default.restore();
  });

  test('.updateCourse sets course data in the store', () => {
    const course = { title: 'Foo' };
    expect(reduxStore.getState().course.title).toBe('');
    reduxStore.dispatch(updateCourse(course));
    const updatedCourse = reduxStore.getState().course;
    const persistedCourse = reduxStore.getState().persistedCourse;
    expect(updatedCourse.title).toBe('Foo');
    expect(persistedCourse.title).not.toBe('Foo');
  });

  test(
    '.persistCourse pushes course data to server via ajax then updates with returned data',
    (done) => {
      const course = { title: 'Foo' };
      persistCourse(course)(reduxStore.dispatch, reduxStore.getState).then(() => {
        expect(reduxStore.getState().course.title).toBe('Bar');
        expect(reduxStore.getState().persistedCourse.title).toBe('Bar');
        done();
      });
    }
  );

  test('.persistCourse resolves to true when the course is saved', async () => {
    const saved = await persistCourse('some/course')(reduxStore.dispatch, reduxStore.getState);
    expect(saved).toBe(true);
  });

  test('.persistCourse keeps the unsaved edits when the server rejects the save', async () => {
    requestModule.default.restore();
    sinon.stub(requestModule, 'default').resolves({
      status: 422,
      ok: false,
      statusText: 'Unprocessable Content',
      text: sinon.fake.resolves(JSON.stringify({ message: 'Not a valid grant ID.', field: 'grant_id' }))
    });
    const saved = { title: 'Saved', grant_id: '1546-24563' };
    reduxStore.dispatch({ type: PERSISTED_COURSE, data: { course: saved } });
    reduxStore.dispatch(updateCourse({ ...saved }));
    reduxStore.dispatch(updateCourse({ title: 'Rejected', grant_id: '0000-0000' }));
    const save = persistCourse('some/course')(reduxStore.dispatch, reduxStore.getState);
    // While the server checks the new grant ID, the field is marked as being checked.
    expect(reduxStore.getState().validations.validations.grant_id.validating).toBe(true);
    const result = await save;
    expect(result).toBe(false);
    // The error goes on the grant ID field rather than in a notification.
    const validation = reduxStore.getState().validations.validations.grant_id;
    expect(validation.valid).toBe(false);
    expect(validation.validating).toBeUndefined();
    expect(validation.message).toBe('Not a valid grant ID.');
    expect(reduxStore.getState().notifications).toEqual([]);
    expect(reduxStore.getState().course.title).toBe('Rejected');
    expect(reduxStore.getState().course.grant_id).toBe('0000-0000');
    expect(reduxStore.getState().persistedCourse.grant_id).toBe('1546-24563');
  });
});
