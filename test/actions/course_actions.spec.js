import sinon from 'sinon';

import '../testHelper';
import { updateCourse, persistCourse } from '../../app/assets/javascripts/actions/course_actions.js';

describe('CourseActions', () => {
  beforeEach(() => {
    sinon.stub($, 'ajax').yieldsTo('success', { course: { title: 'Bar' } });
  });
  afterEach(() => {
    $.ajax.restore();
  });

  it('.updateCourse sets course data in the store', () => {
    const course = { title: 'Foo' };
    expect(reduxStore.getState().course.title).to.eq('');
    reduxStore.dispatch(updateCourse(course));
    const updatedCourse = reduxStore.getState().course;
    const persistedCourse = reduxStore.getState().persistedCourse;
    expect(updatedCourse.title).to.eq('Foo');
    expect(persistedCourse.title).not.to.eq('Foo');
  });

  it('.persistCourse pushes course data to server via ajax then updates with returned data', (done) => {
    const course = { title: 'Foo' };
    persistCourse(course)(reduxStore.dispatch, reduxStore.getState).then(() => {
      expect(reduxStore.getState().course.title).to.eq('Bar');
      expect(reduxStore.getState().persistedCourse.title).to.eq('Bar');
      done();
    });
  });
});
