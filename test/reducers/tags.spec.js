import deepFreeze from 'deep-freeze';
import tags from '../../app/assets/javascripts/reducers/tags';
import {
  RECEIVE_TAGS,
  RECEIVE_ALL_TAGS,
  ADD_TAG,
  REMOVE_TAG
} from '../../app/assets/javascripts/constants';


describe('tags', () => {
  it('should return the initial state', () => {
    const initialState = {
      tags: [],
      allTags: []
    };
    deepFreeze(initialState);

    const result = tags(undefined, {});
    expect(result).toEqual(initialState);
  });

  it('should handle ADD_TAG action', () => {
    const prevState = {
      tags: ['existingTag'],
      allTags: []
    };
    deepFreeze(prevState);

    const action = {
      type: ADD_TAG,
      data: {
        course: {
          tags: ['existingTag', 'newTag']
        }
      }
    };

    const result = tags(prevState, action);

    expect(result).toEqual({
      tags: ['existingTag', 'newTag'],
      allTags: []
    });
  });
  it('should handle REMOVE_TAG action', () => {
    const prevState = {
      tags: ['existingTag', 'tagToRemove'],
      allTags: []
    };
    deepFreeze(prevState);

    const action = {
      type: REMOVE_TAG,
      data: {
        course: {
          tags: ['tagToRemove']
        }
      }
    };

    const result = tags(prevState, action);

    expect(result).toEqual({
      tags: ['tagToRemove'], // Assuming your reducer directly replaces tags with the provided tags
      allTags: []
    });
  });



  it('should handle RECEIVE_TAGS action', () => {
    const prevState = {
      tags: [],
      allTags: []
    };
    deepFreeze(prevState);

    const action = {
      type: RECEIVE_TAGS,
      data: {
        course: {
          tags: ['tag1', 'tag2']
        }
      }
    };

    const result = tags(prevState, action);

    expect(result).toEqual({
      tags: ['tag1', 'tag2'],
      allTags: []
    });
  });

  it('should handle RECEIVE_ALL_TAGS action', () => {
    const prevState = {
      tags: [],
      allTags: ['existingTag']
    };
    deepFreeze(prevState);

    const action = {
      type: RECEIVE_ALL_TAGS,
      data: {
        values: ['tag1', 'tag2']
      }
    };

    const result = tags(prevState, action);

    expect(result).toEqual({
      tags: [],
      allTags: ['tag1', 'tag2']
    });
  });

  it('should return the current state for unknown action types', () => {
    const prevState = {
      tags: ['existingTag'],
      allTags: []
    };
    deepFreeze(prevState);

    const action = {
      type: 'UNKNOWN_ACTION_TYPE'
    };

    const result = tags(prevState, action);

    expect(result).toEqual(prevState);
  });
});
