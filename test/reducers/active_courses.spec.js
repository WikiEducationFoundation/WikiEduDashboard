import deepFreeze from 'deep-freeze';
import active_courses from '../../app/assets/javascripts/reducers/active_courses';
import {
    RECEIVE_ACTIVE_COURSES,
    SORT_ACTIVE_COURSES,
    RECEIVE_CAMPAIGN_ACTIVE_COURSES,
} from '../../app/assets/javascripts/constants';

describe('active_course reducer', () => {
    test('should return initial state when no action nor state is provided', () => {
        const newState = active_courses(undefined, { type: null });
        expect(newState.courses).toEqual([]);
        expect(newState.isLoaded).toBe(false);
    });

    test('should return the same state when RECEIVE_ACTIVE_COURSES is dispatched multiple times with the same data', () => {
        const initialState = {
            courses: [],
            isLoaded: false,
            sort: { key: null, sortKey: null },
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: RECEIVE_ACTIVE_COURSES,
            data: { courses: [{ id: 1, title: 'Course 1' }] },
        };
        const firstState = active_courses(initialState, mockedAction);
        const secondState = active_courses(firstState, mockedAction);
        expect(firstState).toEqual(secondState);
        expect(secondState.courses).toEqual([{ id: 1, title: 'Course 1' }]);
        expect(secondState.isLoaded).toBe(true);
    });

    test('should handle an empty list of courses in RECEIVE_ACTIVE_COURSES', () => {
        const initialState = {
            courses: [{ id: 1, title: 'Existing Course' }],
            isLoaded: true,
            sort: { key: null, sortKey: null },
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: RECEIVE_ACTIVE_COURSES,
            data: { courses: [] },
        };
        const newState = active_courses(initialState, mockedAction);
        expect(newState.courses).toEqual([]);
        expect(newState.isLoaded).toBe(true);
    });

    test('should return active course data  with RECEIVE_ACTIVE_COURSES and set isLoaded to true', () => {
        const initialState = {};
        deepFreeze(initialState);
        const mockedAction = {
            type: RECEIVE_ACTIVE_COURSES,
            data: { courses: [{ title: 'title' }] },
        };
        const newState = active_courses(initialState, mockedAction);
        const expectedState = { courses: [{ title: 'title' }], isLoaded: true };
        expect(newState).toEqual(expectedState);
    });

    test('handles RECEIVE_CAMPAIGN_ACTIVE_COURSES by updating active courses with campaign data ', () => {
        const initialState = { courses: [{ title: 'title' }] };
        deepFreeze(initialState);
        const mockedAction = {
            type: RECEIVE_CAMPAIGN_ACTIVE_COURSES,
            data: { courses: [{ title: 'new title', description: 'new text' }] }
        };
        const newState = active_courses(initialState, mockedAction);
        expect(newState.isLoaded).toBe(true);
        expect(newState.courses).toEqual([{ title: 'new title', description: 'new text' }]);
    });

    test('sort active courses via SORT_ACTIVE_COURSES ', () => {
        const initialState = {
            courses: [{ id: 2, title: 'title two' }, { id: 1, title: 'title one' }],
            sort: { sorKey: null }
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: SORT_ACTIVE_COURSES,
            key: 'id'
        };
        const newState = active_courses(initialState, mockedAction);
        expect(newState.sort.key).toBe('id');
        expect(newState.courses[0].id).toBe(1);
        expect(newState.courses[1].id).toBe(2);
    });

    test('should not modify courses when SORT_ACTIVE_COURSES is dispatched with an invalid key', () => {
        const initialState = {
            courses: [{ id: 2, title: 'Course 2' }, { id: 1, title: 'Course 1' }],
            sort: { sortKey: null, key: null },
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: SORT_ACTIVE_COURSES,
            key: 'nonExistentKey',
        };
        const newState = active_courses(initialState, mockedAction);
        expect(newState.courses).toEqual(initialState.courses); // Should remain unchanged
        expect(newState.sort.key).toBe('nonExistentKey');
    });
});
