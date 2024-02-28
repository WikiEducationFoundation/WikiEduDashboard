import deepFreeze from 'deep-freeze';
import feedback from '../../app/assets/javascripts/reducers/feedback';
import {
  RECEIVE_ARTICLE_FEEDBACK,
  POST_USER_FEEDBACK,
  DELETE_USER_FEEDBACK
} from '../../app/assets/javascripts/constants';

describe('feedback reducer', () => {
  it('should return the initial state', () => {
    const initialState = {};
    deepFreeze(initialState);

    const result = feedback(undefined, {});
    expect(result).toEqual(initialState);
  });

  it('should handle RECEIVE_ARTICLE_FEEDBACK', () => {
    const initialState = {};
    deepFreeze(initialState);

    const action = {
      type: RECEIVE_ARTICLE_FEEDBACK,
      assignmentId: '123',
      data: { feedback: 'Great article!' }
    };

    const result = feedback(initialState, action);
    expect(result).toEqual({ 123: { feedback: 'Great article!' } });
  });

  it('should handle POST_USER_FEEDBACK', () => {
    const initialState = {
       123: { custom: [] }
    };
    deepFreeze(initialState);

    const action = {
      type: POST_USER_FEEDBACK,
      assignmentId: '123',
      feedback: 'Thanks for the feedback!',
      messageId: '456',
      userId: '789'
    };

    const result = feedback(initialState, action);
    expect(result['123'].custom).toEqual([{ message: 'Thanks for the feedback!', messageId: '456', userId: '789' }]);
  });

  it('should handle DELETE_USER_FEEDBACK', () => {
    const initialState = {
        123: { custom: [{ assignmentId: '123', message: 'Feedback 1', messageId: '1', userId: '1' }, { message: 'Feedback 2', messageId: '2', userId: '2' }]
    } };
    deepFreeze(initialState);

    const action = {
      type: DELETE_USER_FEEDBACK,
      assignmentId: '123',
      arrayId: 1
    };

    const result = feedback(initialState, action);
    expect(result['123'].custom).toEqual([{ assignmentId: '123', message: 'Feedback 1', messageId: '1', userId: '1' }]);
  });

  it('should return the current state for unknown action types', () => {
    const initialState = {};
    deepFreeze(initialState);

    const action = {
      type: 'UNKNOWN_ACTION_TYPE'
    };

    const result = feedback(initialState, action);
    expect(result).toEqual(initialState);
  });
});
