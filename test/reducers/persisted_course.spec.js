import persistedCourse from '../../app/assets/javascripts/reducers/persisted_course';
import { RECEIVE_COURSE, PERSISTED_COURSE } from '../../app/assets/javascripts/constants';

describe('persistedCourse reducer', () => {
  it('should return the initial state', () => {
    expect(persistedCourse(undefined, {})).toEqual({});
  });

  it('should handle RECEIVE_COURSE', () => {
    const initialState = {};
    const courseData = { id: 1, title: 'Course Title' };

    const action = {
      type: RECEIVE_COURSE,
      data: { course: courseData }
    };

    expect(persistedCourse(initialState, action)).toEqual(courseData);
  });

  it('should handle PERSISTED_COURSE', () => {
    const initialState = {};
    const courseData = { id: 1, title: 'Course Title' };

    const action = {
      type: PERSISTED_COURSE,
      data: { course: courseData }
    };

    expect(persistedCourse(initialState, action)).toEqual(courseData);
  });

  it('should handle unknown action type', () => {
    const initialState = { id: 1, title: 'Course Title' };
    const action = {
      type: 'UNKNOWN_ACTION'
    };

    expect(persistedCourse(initialState, action)).toEqual(initialState);
  });
});
