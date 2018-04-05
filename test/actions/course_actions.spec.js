import sinon from 'sinon';

import '../testHelper';
import CourseActions from '../../app/assets/javascripts/actions/course_actions.js';
import CourseStore from '../../app/assets/javascripts/stores/course_store.js';

describe('CourseActions', () => {
  beforeEach(() => {
    sinon.stub($, "ajax").yieldsTo("success", { course: { title: 'Bar' } });
  });
  afterEach(() => {
    $.ajax.restore();
  });

  it('.updateCourse sets course data in the store but not the persisted version', (done) => {
    const course = { title: 'Foo' };
    CourseActions.updateCourse(course).then(() => {
      expect(CourseStore.getCourse().title).to.eq('Foo');
      done();
    });
  });

  it('.persistCourse pushes course data to server via ajax then updates with returned data', (done) => {
    const course = { title: 'Foo' };
    CourseActions.persistCourse(course).then(() => {
      expect(CourseStore.getCourse().title).to.eq('Bar');
      done();
    });
  });
});
