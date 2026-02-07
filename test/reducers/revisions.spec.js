import deepFreeze from 'deep-freeze';
import revisions from '../../app/assets/javascripts/reducers/revisions';
import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  RECEIVE_REFERENCES,
  RECEIVE_ASSESSMENTS,
  INCREASE_LIMIT,
  INCREASE_LIMIT_COURSE_SPECIFIC,
  RECEIVE_REFERENCES_COURSE_SPECIFIC
} from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('revisions reducer', () => {
  // Get initial state from reducer (it includes a dynamic date)
  const initialState = revisions(undefined, {});

  // Test that the reducer returns the initial state when called with undefined
  test('should return the initial state', () => {
    const state = revisions(undefined, {});
    expect(state.revisions).toEqual([]);
    expect(state.limitReached).toBe(false);
    expect(state.courseScopedRevisions).toEqual([]);
    expect(state.revisionsLoaded).toBe(false);
    expect(state.courseScopedRevisionsLoaded).toBe(false);
    expect(state.revisionsDisplayed).toEqual([]);
    expect(state.referencesLoaded).toBe(false);
    expect(state.assessmentsLoaded).toBe(false);
  });

  // Test REVISIONS_LOADING action
  test('should handle REVISIONS_LOADING action', () => {
    const currentState = {
      ...initialState,
      revisionsLoaded: true
    };

    const action = {
      type: REVISIONS_LOADING
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.revisionsLoaded).toBe(false);
  });

  // Test COURSE_SCOPED_REVISIONS_LOADING action
  test('should handle COURSE_SCOPED_REVISIONS_LOADING action', () => {
    const currentState = {
      ...initialState,
      courseScopedRevisionsLoaded: true
    };

    const action = {
      type: COURSE_SCOPED_REVISIONS_LOADING
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.courseScopedRevisionsLoaded).toBe(false);
  });

  // Test RECEIVE_REVISIONS action
  test('should handle RECEIVE_REVISIONS action', () => {
    const revisionsList = [
      { revid: 1, title: 'Article 1', date: '2023-01-15' },
      { revid: 2, title: 'Article 2', date: '2023-01-16' }
    ];

    const action = {
      type: RECEIVE_REVISIONS,
      data: {
        course: {
          revisions: revisionsList,
          start: '2023-01-01'
        },
        last_date: '2023-01-10'
      }
    };

    deepFreeze(initialState);
    const newState = revisions(initialState, action);

    expect(newState.revisions).toHaveLength(2);
    expect(newState.revisionsLoaded).toBe(true);
    expect(newState.last_date).toBe('2023-01-10');
    expect(newState.revisionsDisplayed).toHaveLength(2);
    expect(newState.referencesLoaded).toBe(false);
    expect(newState.assessmentsLoaded).toBe(false);
  });

  // Test RECEIVE_REVISIONS concatenates with existing revisions
  test('should concatenate revisions on RECEIVE_REVISIONS', () => {
    const currentState = {
      ...initialState,
      revisions: [{ revid: 1, title: 'Existing' }],
      revisionsDisplayed: [{ revid: 1, title: 'Existing' }]
    };

    const action = {
      type: RECEIVE_REVISIONS,
      data: {
        course: {
          revisions: [{ revid: 2, title: 'New' }],
          start: '2023-01-01'
        },
        last_date: '2023-01-10'
      }
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.revisions).toHaveLength(2);
  });

  // Test RECEIVE_COURSE_SCOPED_REVISIONS action
  test('should handle RECEIVE_COURSE_SCOPED_REVISIONS action', () => {
    const revisionsList = [
      { revid: 1, title: 'Scoped Article 1' },
      { revid: 2, title: 'Scoped Article 2' }
    ];

    const action = {
      type: RECEIVE_COURSE_SCOPED_REVISIONS,
      data: {
        course: {
          revisions: revisionsList,
          start: '2023-01-01'
        },
        last_date: '2023-01-10'
      }
    };

    deepFreeze(initialState);
    const newState = revisions(initialState, action);

    expect(newState.courseScopedRevisions).toHaveLength(2);
    expect(newState.courseScopedRevisionsLoaded).toBe(true);
    expect(newState.last_date_course_specific).toBe('2023-01-10');
    expect(newState.revisionsDisplayedCourseSpecific).toHaveLength(2);
  });

  // Test INCREASE_LIMIT action
  test('should handle INCREASE_LIMIT action', () => {
    // Create state with more revisions than displayed
    const allRevisions = [];
    for (let i = 0; i < 100; i += 1) {
      allRevisions.push({ revid: i, title: `Article ${i}` });
    }

    const currentState = {
      ...initialState,
      revisions: allRevisions,
      revisionsDisplayed: allRevisions.slice(0, 10),
      sort: { key: null, sortKey: null }
    };

    const action = {
      type: INCREASE_LIMIT
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    // Should add 50 more (REVISIONS_INCREMENT)
    expect(newState.revisionsDisplayed.length).toBe(60);
    expect(newState.revisionsLoaded).toBe(true);
  });

  // Test INCREASE_LIMIT_COURSE_SPECIFIC action
  test('should handle INCREASE_LIMIT_COURSE_SPECIFIC action', () => {
    const allRevisions = [];
    for (let i = 0; i < 100; i += 1) {
      allRevisions.push({ revid: i, title: `Article ${i}` });
    }

    const currentState = {
      ...initialState,
      courseScopedRevisions: allRevisions,
      revisionsDisplayedCourseSpecific: allRevisions.slice(0, 10),
      sort: { key: null, sortKey: null }
    };

    const action = {
      type: INCREASE_LIMIT_COURSE_SPECIFIC
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.revisionsDisplayedCourseSpecific.length).toBe(60);
    expect(newState.courseScopedRevisionsLoaded).toBe(true);
  });

  // Test RECEIVE_REFERENCES action
  test('should handle RECEIVE_REFERENCES action', () => {
    const currentState = {
      ...initialState,
      revisions: [
        { revid: 1, title: 'Article 1' },
        { revid: 2, title: 'Article 2' }
      ],
      revisionsDisplayed: [
        { revid: 1, title: 'Article 1' }
      ]
    };

    const action = {
      type: RECEIVE_REFERENCES,
      data: {
        referencesAdded: {
          1: 5,
          2: 10
        }
      }
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.referencesLoaded).toBe(true);
    expect(newState.revisions[0].references_added).toBe(5);
    expect(newState.revisions[1].references_added).toBe(10);
    expect(newState.revisionsDisplayed[0].references_added).toBe(5);
  });

  // Test RECEIVE_REFERENCES_COURSE_SPECIFIC action
  test('should handle RECEIVE_REFERENCES_COURSE_SPECIFIC action', () => {
    const currentState = {
      ...initialState,
      courseScopedRevisions: [
        { revid: 1, title: 'Article 1' }
      ],
      revisionsDisplayedCourseSpecific: [
        { revid: 1, title: 'Article 1' }
      ]
    };

    const action = {
      type: RECEIVE_REFERENCES_COURSE_SPECIFIC,
      data: {
        referencesAdded: {
          1: 3
        }
      }
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.courseSpecificReferencesLoaded).toBe(true);
    expect(newState.courseScopedRevisions[0].references_added).toBe(3);
  });

  // Test RECEIVE_ASSESSMENTS action
  test('should handle RECEIVE_ASSESSMENTS action', () => {
    const currentState = {
      ...initialState,
      revisions: [
        { revid: 1, title: 'Article 1' }
      ],
      revisionsDisplayed: [
        { revid: 1, title: 'Article 1' }
      ]
    };

    const action = {
      type: RECEIVE_ASSESSMENTS,
      data: {
        assessments: {
          1: {
            rating_num: 5,
            pretty_rating: 'GA',
            rating: 'good'
          }
        }
      }
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.assessmentsLoaded).toBe(true);
    expect(newState.revisions[0].rating_num).toBe(5);
    expect(newState.revisions[0].pretty_rating).toBe('GA');
    expect(newState.revisions[0].rating).toBe('good');
  });

  // Test RECEIVE_ASSESSMENTS_COURSE_SPECIFIC action
  test('should handle RECEIVE_ASSESSMENTS_COURSE_SPECIFIC action', () => {
    const currentState = {
      ...initialState,
      courseScopedRevisions: [
        { revid: 1, title: 'Article 1' }
      ],
      revisionsDisplayedCourseSpecific: [
        { revid: 1, title: 'Article 1' }
      ]
    };

    const action = {
      type: 'RECEIVE_ASSESSMENTS_COURSE_SPECIFIC',
      data: {
        assessments: {
          1: {
            rating_num: 3,
            pretty_rating: 'C',
            rating: 'c-class'
          }
        }
      }
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.courseSpecificAssessmentsLoaded).toBe(true);
    expect(newState.courseScopedRevisions[0].rating_num).toBe(3);
  });

  // Test SORT_REVISIONS action
  test('should handle SORT_REVISIONS action', () => {
    const currentState = {
      ...initialState,
      revisionsDisplayed: [
        { revid: 1, title: 'Zebra Article', characters: 100 },
        { revid: 2, title: 'Alpha Article', characters: 50 }
      ],
      revisionsDisplayedCourseSpecific: [
        { revid: 3, title: 'Beta Article', characters: 75 }
      ],
      sort: { key: null, sortKey: null }
    };

    const action = {
      type: SORT_REVISIONS,
      key: 'title'
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    expect(newState.sort.key).toBe('title');
    expect(newState.revisionsDisplayed).toHaveLength(2);
  });

  // Test SORT_REVISIONS toggles sort direction when sorting by same key
  test('should toggle sort direction on SORT_REVISIONS with same key', () => {
    const currentState = {
      ...initialState,
      revisionsDisplayed: [
        { revid: 1, title: 'Article 1' },
        { revid: 2, title: 'Article 2' }
      ],
      revisionsDisplayedCourseSpecific: [],
      sort: { key: 'title', sortKey: 'title' }
    };

    const action = {
      type: SORT_REVISIONS,
      key: 'title'
    };

    deepFreeze(currentState);
    const newState = revisions(currentState, action);

    // sortKey should be reset to null when sorting descending
    expect(newState.sort.key).toBe('title');
  });

  // Test that unknown action types return the current state unchanged
  test('should return the current state for unknown action types', () => {
    const action = {
      type: 'UNKNOWN_ACTION'
    };

    deepFreeze(initialState);
    const newState = revisions(initialState, action);
    expect(newState).toEqual(initialState);
  });
});

