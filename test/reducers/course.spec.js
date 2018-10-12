import deepFreeze from 'deep-freeze';
import course from '../../app/assets/javascripts/reducers/course';
import { UPDATE_COURSE } from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('course reducer', () => {
  it('updates an attribute via UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    const action = { type: UPDATE_COURSE, course: { title: 'new title' } };
    deepFreeze(initialState);

    const newState = course(initialState, action);
    expect(newState.title).to.eq('new title');
    expect(newState.term).to.eq('old term');
  });
});
