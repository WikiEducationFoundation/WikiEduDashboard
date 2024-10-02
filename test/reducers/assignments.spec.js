import deepFreeze from 'deep-freeze';
import {
    RECEIVE_ASSIGNMENTS,
    ADD_ASSIGNMENT,
    DELETE_ASSIGNMENT,
    UPDATE_ASSIGNMENT,
    LOADING_ASSIGNMENTS,
} from '../../app/assets/javascripts/constants';
import assignments from '../../app/assets/javascripts/reducers/assignments';

const receivedData = {
    assignments: [
        { title: 'second title', course_slug: 'second_slug' },
        { title: 'first title', course_slug: 'first_slug' },
    ],
    lastRequestTimestamp: Date.now(),
};

describe('assignments reducer', () => {
    test('should return initial state when no action nor state  is provided', () => {
        const newState = assignments(undefined, { type: null });
        expect(newState.assignments).toEqual([]);
        expect(newState.loading).toBe(true);
        expect(newState.lastRequestTimestamp).toBe(0);
    });

    test('should return the received assignments in sorted format when RECEIVE_ASSIGNMENTS is dispatched', () => {
        const initialState = {
            assignments: [],
            sort: { sortKey: null, key: null },
            loading: true,
            lastRequestTimestamp: 0,
        };
        const mockedAction = {
            type: RECEIVE_ASSIGNMENTS,
            data: { course: { assignments: receivedData.assignments, lastRequestTimestamp: receivedData.lastRequestTimestamp } },
        };
        const newState = assignments(initialState, mockedAction);
        expect(typeof newState.lastRequestTimestamp).toBe('number');
        expect(newState.assignments).toEqual(receivedData.assignments);
        expect(newState.loading).toBe(false);
    });

    test('should return the same state when RECEIVE_ASSIGNMENTS is dispatched multiple times with the same data', () => {
        const initialState = {
            assignments: [],
            sort: { sortKey: null, key: null },
            loading: true,
            lastRequestTimestamp: 0,
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: RECEIVE_ASSIGNMENTS,
            data: { course: { assignments: receivedData.assignments } },
        };
        const firstState = assignments(initialState, mockedAction);
        const secondState = assignments(firstState, mockedAction);
        expect(firstState.sortKey).toBe('article_title');
        expect(secondState.sortKey).toBe(null); // confirm this is how it is intended to work

        expect(firstState.assignments).toEqual([...secondState.assignments].reverse());
        expect(secondState.assignments).toEqual([...receivedData.assignments].reverse());

        expect(firstState.loading).toBe(false);
        expect(secondState.loading).toBe(false);
    });

    test('should add a new assignment to the existing list of assignments', () => {
        const initialState = {
            assignments: [{ id: 1, title: 'First Assignment', course_slug: 'first_course' }],
            sortKey: null,
            loading: true,
            lastRequestTimestamp: 0,
        };

        deepFreeze(initialState);
        const newAssignment = {
            id: 2,
            title: 'Second Assignment',
            course_slug: 'second_course'
        };

        const mockedAction = {
            type: ADD_ASSIGNMENT,
            data: newAssignment
        };

        const newState = assignments(initialState, mockedAction);
        expect(newState.assignments.length).toBe(2);
        expect(newState.assignments).toContainEqual(newAssignment);
        expect(newState.assignments).toContainEqual(initialState.assignments[0]);
        expect(newState).not.toBe(initialState);
    });

    test('should add an assignment when assignments array is empty', () => {
        const initialState = {
            assignments: [],
            sortKey: null,
            loading: true,
            lastRequestTimestamp: 0,
        };
        deepFreeze(initialState);
        const newAssignment = {
            id: 1,
            title: 'New Assignment',
            course_slug: 'new_course'
        };

        const mockedAction = {
            type: ADD_ASSIGNMENT,
            data: newAssignment
        };

        const newState = assignments(initialState, mockedAction);
        expect(newState.assignments.length).toBe(1);
        expect(newState.assignments).toContainEqual(newAssignment);
    });

    test('should prevent adding duplicate assignments with the same id', () => {
        const initialState = {
            assignments: [
                { id: 1, title: 'Existing Assignment', course_slug: 'existing_course' }
            ],
            sortKey: null,
            loading: true,
            lastRequestTimestamp: 0,
        };

        deepFreeze(initialState);

        const duplicateAssignment = {
            id: 1, // Same ID as existing
            title: 'Existing Assignment',
            course_slug: 'existing_course'
        };

        const mockedAction = {
            type: ADD_ASSIGNMENT,
            data: duplicateAssignment
        };

        const newState = assignments(initialState, mockedAction);
        expect(newState.assignments.length).toBe(1);
        expect(newState.assignments).toEqual(initialState.assignments);
    });


    test('should delete the specified assignment, not modify the original state, and handle missing assignment gracefully', () => {
        const initialState = {
            assignments: [
                { id: 1, title: 'First Assignment', course_slug: 'first_course' },
                { id: 2, title: 'Second Assignment', course_slug: 'second_course' },
                { id: 3, title: 'Third Assignment', course_slug: 'third_course' }
            ],
            sortKey: null,
            loading: false,
            lastRequestTimestamp: 0,
        };
        deepFreeze(initialState);
        const deleteAssignmentId = 2;

        const mockedAction = {
            type: DELETE_ASSIGNMENT,
            data: {
                assignmentId: deleteAssignmentId
            }
        };

        const newState = assignments(initialState, mockedAction);
        expect(newState).not.toBe(initialState);
        expect(newState.assignments).toHaveLength(2);
        expect(newState.assignments).not.toContainEqual({
            id: deleteAssignmentId,
            title: 'Second Assignment',
            course_slug: 'second_course'
        });
        expect(newState.assignments).toContainEqual(initialState.assignments[0]);
        expect(newState.assignments).toContainEqual(initialState.assignments[2]);

        const invalidAction = {
            type: DELETE_ASSIGNMENT,
            data: { assignmentId: 999 }
        };
        const stateAfterInvalidDelete = assignments(newState, invalidAction);
        expect(stateAfterInvalidDelete).toEqual(newState);
    });

    test('should update the specified assignment, not modify the original state, and handle missing assignment gracefully', () => {
        const initialState = {
            assignments: [
                { id: 1, title: 'First Assignment', course_slug: 'first_course' },
                { id: 2, title: 'Second Assignment', course_slug: 'second_course' },
                { id: 3, title: 'Third Assignment', course_slug: 'third_course' }
            ],
            sortKey: null,
            loading: false,
            lastRequestTimestamp: 0,
        };

        deepFreeze(initialState);

        const updatedAssignment = {
            id: 2,
            title: 'Updated Second Assignment',
            course_slug: 'updated_course'
        };

        const mockedAction = {
            type: UPDATE_ASSIGNMENT,
            data: {
                assignment: updatedAssignment
            }
        };

        const newState = assignments(initialState, mockedAction);
        expect(newState).not.toBe(initialState);
        expect(newState.assignments).toHaveLength(3);
        expect(newState.assignments).toContainEqual(updatedAssignment);

        expect(newState.assignments).toContainEqual(initialState.assignments[0]);
        expect(newState.assignments).toContainEqual(initialState.assignments[2]);

        const nonExistentUpdateAction = {
            type: UPDATE_ASSIGNMENT,
            data: { assignment: { id: 999, title: 'Non-existent Assignment', course_slug: 'non_existent_course' } }
        };

        const stateAfterInvalidUpdate = assignments(newState, nonExistentUpdateAction);
        expect(stateAfterInvalidUpdate).not.toEqual(newState);
    });

    test('should set loading to true when LOADING_ASSIGNMENTS is dispatched', () => {
        const initialState = {
            assignments: [{ id: 1, title: 'First Assignment', course_slug: 'first_course' }, { id: 2, title: 'Second Assignment', course_slug: 'second_course' }],
            sortKey: null,
            loading: false,
            lastRequestTimestamp: 0,
        };

        deepFreeze(initialState);

        const mockedAction = {
            type: LOADING_ASSIGNMENTS,
        };

        const newState = assignments(initialState, mockedAction);

        expect(newState).not.toBe(initialState);
        expect(newState.loading).toBe(true);
        expect(newState.assignments).toEqual(initialState.assignments);
        expect(newState.sortKey).toBe(initialState.sortKey);
        expect(newState.lastRequestTimestamp).toBe(initialState.lastRequestTimestamp);
    });
});