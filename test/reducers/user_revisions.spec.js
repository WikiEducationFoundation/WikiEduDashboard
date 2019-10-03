import deepFreeze from 'deep-freeze';
import '../testHelper';
import userRevisions from '../../app/assets/javascripts/reducers/user_revisions';
import { RECEIVE_USER_REVISIONS } from '../../app/assets/javascripts/constants';

describe('user revisions reducer', () => {
  test(
    'should return initial state when no action nor state is provided',
    () => {
      const newState = userRevisions(undefined, { type: null });
      expect(typeof newState).toBe('object');
    }
  );

  test(
    'receives user revisions data with user identification as key via RECEIVE_USER_REVISIONS',
    () => {
      const initialState = {};
      deepFreeze(initialState);
      const mockedAction = {
        type: RECEIVE_USER_REVISIONS,
        data: { course: { revisions: [] } },
        userId: 3
      };

      const firstState = userRevisions(initialState, mockedAction);
      expect(Array.isArray(firstState[3])).toBe(true);
      expect(firstState[4]).toBeUndefined();

      mockedAction.userId = 4;
      const secondState = userRevisions(firstState, mockedAction);
      expect(Array.isArray(secondState[4])).toBe(true);
      expect(Array.isArray(secondState[3])).toBe(true);
    }
  );
});
