import deepFreeze from 'deep-freeze';
import exercises from '../../app/assets/javascripts/reducers/exercises';
import { EXERCISE_FETCH_STARTED, EXERCISE_FETCH_COMPLETED } from '../../app/assets/javascripts/constants';
import '../testHelper';

const exerciseData = [
    {
      training_modules: [
        { kind: 1, deadline_status: 'complete', flags: { marked_complete: true } },
        { kind: 2, deadline_status: 'incomplete' }
      ]
    },
    {
      training_modules: [
        { kind: 1, deadline_status: 'complete' },
        { kind: 2, deadline_status: 'incomplete', flags: { marked_complete: false } },
      ]
    },
    {
      training_modules: [
        { kind: 1, deadline_status: 'incomplete', flags: { marked_complete: false } },
        { kind: 1, deadline_status: 'complete', },
        { kind: 1, deadline_status: 'incomplete' },
      ]
    },
    {
      training_modules: []
    },
    {
      training_modules: [
        { kind: 2, deadline_status: 'complete' }
      ]
    },
    {
      training_modules: [
        { kind: 1, deadline_status: 'complete', flags: { marked_complete: true } },
        { kind: 2, deadline_status: 'incomplete', flags: { marked_complete: false } },
        { kind: 1, deadline_status: 'complete' },
      ]
    }
  ];


describe('exercises reducer', () => {
    test('returns initial state when no action or state is provided', () => {
        const newState = exercises(undefined, { type: null });
        expect(newState.complete).toEqual([]);
        expect(newState.incomplete).toEqual([]);
        expect(newState.unread).toEqual([]);
        expect(newState.loading).toBe(true);
    });

    test('setLoading State to true when exercises are being fetched using EXERCISE_FETCH_STARTED', () => {
       const initialState = { complete: [], incomplete: [], unread: [], loading: true };
            deepFreeze(initialState);
            const mockedAction = {
                type: EXERCISE_FETCH_STARTED,
            };

            const newState = exercises(initialState, mockedAction);
            expect(newState.complete).toEqual([]);
            expect(newState.complete.length).toEqual(0);
            expect(newState.incomplete).toEqual([]);
            expect(newState.unread).toEqual([]);
            expect(newState.loading).toBe(true);
    });

    test('should return state data by categorizing data blocks using EXERCISE_FETCH_COMPLETED', () => {
       const initialState = { complete: [], incomplete: [], unread: [], loading: true };
            deepFreeze(initialState);
            const mockedAction = {
                type: EXERCISE_FETCH_COMPLETED,
                data: { blocks: exerciseData }
            };

            const newState = exercises(initialState, mockedAction);
            expect(newState.complete.length).toBeGreaterThan(0);
            expect(newState.incomplete.length).toBeGreaterThan(0);
            expect(newState.unread.length).toBeGreaterThan(0);
            expect(newState.loading).toBe(false);
    });

    test('categorizes exercises correctly based on deadline_status and marked_complete flag when EXERCISE_FETCH_COMPLETED is dispatched', () => {
       const initialState = { complete: [], incomplete: [], unread: [], loading: true };
       deepFreeze(initialState);
            const mockedAction = {
                type: EXERCISE_FETCH_COMPLETED,
                data: { blocks: exerciseData }
            };

            const newState = exercises(initialState, mockedAction);
            // Exercises with deadline_status "complete" and flagged as marked_complete
            expect(newState.complete.length).toBe(2);
            // Exercises with deadline_status "complete" but not marked as complete (no marked_complete flag or flagged false)
            expect(newState.incomplete.length).toBe(3);
            // Exercises with deadline_status "incomplete" or not flagged as marked_complete
            expect(newState.unread.length).toBe(2);
    });

    test('only processes exercises with kind 1', () => {
        const initialState = { complete: [], incomplete: [], unread: [], loading: true };
        deepFreeze(initialState);
        const mockedAction = {
          type: EXERCISE_FETCH_COMPLETED,
          data: { blocks: [
            { training_modules: [{ kind: 1, deadline_status: 'complete' }] },
            { training_modules: [{ kind: 2, deadline_status: 'complete' }] }
          ] }
        };
        const newState = exercises(initialState, mockedAction);
        expect(newState.incomplete.length).toBe(1);
      });
});
