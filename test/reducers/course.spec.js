import deepFreeze from 'deep-freeze';
import course from '../../app/assets/javascripts/reducers/course';
import * as ACTION_TYPES from '../../app/assets/javascripts/constants/course';
import '../testHelper';

describe('course reducer', () => {
  it("doesn't modify passed state", () => {
    const initialState = {};
    deepFreeze(initialState);

    Object.values(ACTION_TYPES).forEach((actionType) => {
      const action = { type: actionType };
      const actionBlackHole = new Proxy(action, {
        get: function (target, key) {
          if (key === 'type') {
            return target.type;
          }

          return actionBlackHole;
        }
      });
      course(initialState, actionBlackHole);
    });
  });

  it('updates an attribute via UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    const action = { type: ACTION_TYPES.UPDATE_COURSE, course: { title: 'new title' } };
    deepFreeze(initialState);

    const newState = course(initialState, action);
    expect(newState.title).to.eq('new title');
    expect(newState.term).to.eq('old term');
  });
});
