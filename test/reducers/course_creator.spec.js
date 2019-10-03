import deepFreeze from 'deep-freeze';
import reducer from '../../app/assets/javascripts/reducers/course_creator';
import '../testHelper';

describe('Course creator reducer', () => {
  let initialState;
  beforeEach(() => {
    initialState = {
      defaultCourseType: 'BasicCourse',
      courseStringPrefix: 'courses',
      useStartAndEndTimes: false
    };
    deepFreeze(initialState);
  });
  test('should return the initial state', () => {
    const state = reducer(undefined, { type: null });
    expect(state).toEqual(initialState);
  });
});
