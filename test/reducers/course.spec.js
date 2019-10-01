import deepFreeze from 'deep-freeze';
import course from '../../app/assets/javascripts/reducers/course';
import {
  UPDATE_COURSE,
  RECEIVE_COURSE,
  RECEIVE_COURSE_UPDATE,
  PERSISTED_COURSE,
  CREATED_COURSE,
  RECEIVE_INITIAL_CAMPAIGN,
  ADD_CAMPAIGN,
  RECEIVE_COURSE_CLONE,
  DISMISS_SURVEY_NOTIFICATION,
  TOGGLE_EDITING_SYLLABUS,
  START_SYLLABUS_UPLOAD,
  SYLLABUS_UPLOAD_SUCCESS,
  LINKED_TO_SALESFORCE,
  DELETE_CAMPAIGN
} from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('course reducer', () => {
  test(
    'should return initial state when no action nor state is provided',
    () => {
      const newState = course(undefined, { type: null });
      expect(newState.title).toBe('');
      expect(newState.description).toBe('');
      expect(newState.weekdays).toBe('0000000');
    }
  );

  test(
    'should return data course with RECEIVE_COURSE and set loading to false',
    () => {
      const initialState = {};
      deepFreeze(initialState);
      const mockedAction = {
        type: RECEIVE_COURSE,
        data: { course: { title: 'title' } }
      };

      const newState = course(initialState, mockedAction);
      const expectedState = { title: 'title', loading: false };
      expect(newState).toEqual(expectedState);
    }
  );

  test(
    'keeps track of which stats have been updated with RECEIVE_COURSE_UPDATE',
    () => {
      const initialState = {
        title: 'title',
        created_count: 0,
        edited_count: 0,
        student_count: 3
      };
      deepFreeze(initialState);

      const mockedAction = {
        type: RECEIVE_COURSE_UPDATE,
        data: { course: { ...initialState, created_count: 1, student_count: 5 } }
      };

      const newState = course(initialState, mockedAction);
      expect(newState.newStats.created_count).toBe(true);
      expect(newState.newStats.student_count).toBe(true);
      expect(newState.newStats.edited_count).toBe(false);
      expect(newState.created_count).toBe(1);
      expect(newState.student_count).toBe(5);
      expect(newState.edited_count).toBe(0);
    }
  );

  test('only updates stat information with RECEIVE_COURSE_UPDATE', () => {
    const initialState = {
      title: 'new title',
      description: 'initial description',
    };
    deepFreeze(initialState);

    const newState = course(initialState, {
      type: UPDATE_COURSE,
      course: { description: 'a new description' }
    });

    const finalState = course(newState, {
      type: RECEIVE_COURSE_UPDATE,
      data: { course: { ...initialState } }
    });
    expect(finalState.description).toBe('a new description');
  });

  test('updates course with receive data via PERSITED_COURSE', () => {
    const initialState = { description: 'initial description' };
    deepFreeze(initialState);
    const mockedAction = {
      type: PERSISTED_COURSE,
      data: { course: { title: 'new title' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState).toEqual({
      description: 'initial description',
      title: 'new title'
    });
  });

  test('adds current action course to state with UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    deepFreeze(initialState);
    const mockedAction = {
      type: UPDATE_COURSE,
      course: { title: 'new title' }
    };

    const newState = course(initialState, mockedAction);
    expect(newState).toEqual({ title: 'new title', term: 'old term' });
  });

  test('returns created course as new state with CREATED_COURSE', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: CREATED_COURSE,
      data: { course: { title: 'title' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).toBe('title');
  });

  test(
    'returns state and initial campaign data with RECEIVE_INITIAL_CAMPAIGN',
    () => {
      const initialState = {
        title: 'default title',
        description: 'desc',
        type: '',
        passcode: 'foobar'
      };
      deepFreeze(initialState);
      const campaign = {
        id: 2,
        title: 'title',
        template_description: 'description',
        default_course_type: 'type',
        default_passcode: 'pass'
      };
      const mockedAction = {
        type: RECEIVE_INITIAL_CAMPAIGN,
        data: { campaign: campaign }
      };

      const newState = course(initialState, mockedAction);
      expect(newState.title).toBe('default title');
      expect(newState.description).toBe('description');
      expect(newState.type).toBe('type');
      expect(newState.passcode).toBe('pass');
    }
  );

  test(
    'updates state when a campaing is deleted or added with ADD_CAMAPAIGN and DELETE_CAMPAIGN',
    () => {
      const initialState = { title: 'title' };
      deepFreeze(initialState);
      let mockedAction = {
        type: ADD_CAMPAIGN,
        data: { course: { published: true } }
      };

      let newState = course(initialState, mockedAction);
      expect(newState).toEqual({ title: 'title', published: true });

      mockedAction = {
        type: DELETE_CAMPAIGN,
        data: { course: { published: false } }
      };

      newState = course(initialState, mockedAction);
      expect(newState).toEqual({ title: 'title', published: false });
    }
  );

  test('returns cloned course with RECEIVE_COURSE_CLONE', () => {
    const initialState = { title: 'old title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_COURSE_CLONE,
      data: { course: { title: 'clone course' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).toBe('clone course');
  });

  test(
    'removes notification from survey notifications array with DISMISS_SURVEY_NOTIFICATION',
    () => {
      const initialState = {
        survey_notifications: [{ id: 1 }, { id: 2 }, { id: 3 }]
      };
      deepFreeze(initialState);
      const mockedAction = {
        type: DISMISS_SURVEY_NOTIFICATION,
        id: 3
      };

      const newState = course(initialState, mockedAction);
      expect(newState.survey_notifications).toEqual([{ id: 1 }, { id: 2 }]);
    }
  );

  test('toggles boolean of state attribute with TOGGLE_EDITING_SYLLABUS', () => {
    const initialState = { title: 'title', editingSyllabus: true };
    deepFreeze(initialState);
    const mockedAction = {
      type: TOGGLE_EDITING_SYLLABUS
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).toBe('title');
    expect(newState.editingSyllabus).toBe(false);
  });

  test('sets state attribute with START_SYLLABUS_UPLOAD', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: START_SYLLABUS_UPLOAD
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).toBe('title');
    expect(newState.uploadingSyllabus).toBe(true);
  });

  test(
    'reset state attributes and returns updated state with response via SYLLABUS UPLOAD SUCCESS ',
    () => {
      const initialState = {
        title: 'title',
        uploadingSyllabus: true,
        editingSyllabus: true,
        syllabus: ''
      };
      deepFreeze(initialState);
      const mockedAction = {
        type: SYLLABUS_UPLOAD_SUCCESS,
        syllabus: 'foobar'
      };

      const newState = course(initialState, mockedAction);
      expect(newState.title).toBe('title');
      expect(newState.uploadingSyllabus).toBe(false);
      expect(newState.editingSyllabus).toBe(false);
      expect(newState.syllabus).toBe('foobar');
    }
  );

  test('returns state and salesforce attributes LINKED_TO_SALESFORCE', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: LINKED_TO_SALESFORCE,
      data: { flags: true }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).toBe('title');
    expect(newState.flags).toBe(true);
  });
});
