import reducer from '../../app/assets/javascripts/reducers/uploads';
import { SET_UPLOAD_METADATA } from '../../app/assets/javascripts/constants';

const stateWith = uploads => ({
  ...reducer(undefined, { type: 'INIT' }),
  uploads,
});

const commonsResponse = id => ({
  query: {
    pages: {
      [id]: {
        imageinfo: [{
          extmetadata: { Credit: { value: 'Example credit' } },
          thumburl: 'https://example.org/thumb.jpg',
        }],
      },
    },
  },
});

describe('uploads reducer', () => {
  describe('SET_UPLOAD_METADATA', () => {
    it('marks requested uploads as failed when no metadata is returned', () => {
      const state = stateWith([{ id: 1 }]);
      const action = { type: SET_UPLOAD_METADATA, data: [undefined], requestedIds: [1] };

      const newState = reducer(state, action);

      expect(newState.uploads[0].fetchState).toBe('failed');
      expect(newState.uploads[0].credit).toBe('Not found');
    });

    it('sets credit and marks uploads as fetched when metadata is returned', () => {
      const state = stateWith([{ id: 1 }]);
      const action = { type: SET_UPLOAD_METADATA, data: [commonsResponse(1)], requestedIds: [1] };

      const newState = reducer(state, action);

      expect(newState.uploads[0].fetchState).toBe(true);
      expect(newState.uploads[0].credit).toBe('Example credit');
    });

    it('leaves uploads that were not requested unchanged', () => {
      const state = stateWith([{ id: 1 }, { id: 2 }]);
      const action = { type: SET_UPLOAD_METADATA, data: [undefined], requestedIds: [1] };

      const newState = reducer(state, action);

      expect(newState.uploads[0].fetchState).toBe('failed');
      expect(newState.uploads[0].credit).toBe('Not found');
      expect(newState.uploads[1].fetchState).toBeUndefined();
    });

    it('marks only the uploads from a failed batch when another batch succeeds', () => {
      const state = stateWith([{ id: 1 }, { id: 2 }]);
      const action = {
        type: SET_UPLOAD_METADATA,
        data: [commonsResponse(1), undefined],
        requestedIds: [1, 2],
      };

      const newState = reducer(state, action);

      expect(newState.uploads[0].fetchState).toBe(true);
      expect(newState.uploads[0].credit).toBe('Example credit');
      expect(newState.uploads[1].fetchState).toBe('failed');
      expect(newState.uploads[1].credit).toBe('Not found');
    });

    it('does not mark an already-fetched upload as failed', () => {
      const state = stateWith([{ id: 1, fetchState: true, credit: 'Example credit' }]);
      const action = { type: SET_UPLOAD_METADATA, data: [undefined], requestedIds: [1] };

      const newState = reducer(state, action);

      expect(newState.uploads[0].fetchState).toBe(true);
      expect(newState.uploads[0].credit).toBe('Example credit');
    });
  });
});
