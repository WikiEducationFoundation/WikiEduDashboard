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

    test('should return active course campaign data with RECEIVE_CAMPAIGN_ACTIVE_COURSES ', () => {
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
            courses: [{ id: 1, title: 'title one' }, { id: 2, title: 'title two' }],
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
});

