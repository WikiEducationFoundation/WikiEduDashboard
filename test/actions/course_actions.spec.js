import '../testHelper';
import { updateCourse, persistCourse } from '../../app/assets/javascripts/actions/course_actions.js';

describe('CourseActions', () => {
  beforeEach(() => {
    sinon.stub($, 'ajax').yieldsTo('success', { course: { title: 'Bar' } });
  });
  afterEach(() => {
    $.ajax.restore();
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
});
