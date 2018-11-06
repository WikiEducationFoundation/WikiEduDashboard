import deepFreeze from 'deep-freeze';
import course from '../../app/assets/javascripts/reducers/course';
import { UPDATE_COURSE, RECEIVE_COURSE, RECEIVE_COURSE_UPDATE, PERSISTED_COURSE } from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('course reducer', () => {

  it('receives a course via RECEIVE_COURSE', () => {
    const initialState = {};
    const action = { type: RECEIVE_COURSE, data: { course: { title: 'title' } }  };
    deepFreeze(initialState);

    const newState = course(initialState, action);
    expect(newState).to.deep.eq(action.data.course);
  });

  it('receives a course update via RECEIVE_COURSE_UPDATE with newStats', () => {
    const initialState = {};
    const action = { type: RECEIVE_COURSE_UPDATE, data: { course: { title: 'title' } }  };
    deepFreeze(initialState);

    const newStats = [ "createdCount", "editedCount", "editCount", "studentCount", "wordCount", "viewCount", "uploadCount"];

    const newState = course(initialState, action);
    expect(newState.title).to.deep.eq(action.data.course.title);
    expect(newState.newStats).to.have.all.keys(newStats);
  });

  it('persisted course via PERSISTED_COURSE', () => {
    const initialState = {description: 'initial description'};
    const action = { type: PERSISTED_COURSE, data: { course: { title: 'new title' } }  };
    deepFreeze(initialState);

    const newState = course(initialState, action);
    expect(newState).to.deep.eq({description: 'initial description', title: 'new title'})
  });

  it('updates an attribute via UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    const action = { type: UPDATE_COURSE, course: { title: 'new title' } };
    deepFreeze(initialState);

    const newState = course(initialState, action);
    expect(newState.title).to.eq('new title');
    expect(newState.term).to.eq('old term');
  });
});
