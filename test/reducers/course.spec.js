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
  it('should return initial state when no action nor state is provided', () => {
    const newState = course(undefined, { type: null });
    expect(newState.title).to.eq('');
    expect(newState.description).to.eq('');
    expect(newState.weekdays).to.eq('0000000');
  });

  it('should return data course with RECEIVE_COURSE', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_COURSE,
      data: { course: { title: 'title' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq(mockedAction.data.course);
  });

  it('keeps track of which stats have been updated with RECEIVE_COURSE_UPDATE', () => {
    const initialState = { title: 'title', created_count: 0, edited_count: 0 };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_COURSE_UPDATE,
      data: { course: { created_count: 1, edited_count: 0 } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.newStats.createdCount).to.eq(true);
    expect(newState.newStats.editedCount).to.eq(false);
  });

  it('updates course with receive data via PERSITED_COURSE', () => {
    const initialState = { description: 'initial description' };
    deepFreeze(initialState);
    const mockedAction = {
      type: PERSISTED_COURSE,
      data: { course: { title: 'new title' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({
      description: 'initial description',
      title: 'new title'
    });
  });

  it('adds current action course to state with UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    deepFreeze(initialState);
    const mockedAction = {
      type: UPDATE_COURSE,
      course: { title: 'new title' }
    };

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'new title', term: 'old term' });
  });

  it('returns created course as new state with CREATED_COURSE', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: CREATED_COURSE,
      data: { course: { title: 'title' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('title');
  });

  it('returns state and initial campaign data with RECEIVE_INITIAL_CAMPAIGN', () => {
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
    expect(newState.title).to.eq('default title');
    expect(newState.description).to.eq('description');
    expect(newState.type).to.eq('type');
    expect(newState.passcode).to.eq('pass');
  });

  it('updates state when a campaing is deleted or added with ADD_CAMAPAIGN and DELETE_CAMPAIGN', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    let mockedAction = {
      type: ADD_CAMPAIGN,
      data: { course: { published: true } }
    };

    let newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'title', published: true });

    mockedAction = {
      type: DELETE_CAMPAIGN,
      data: { course: { published: false } }
    };

    newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'title', published: false });
  });

  it('returns cloned course with RECEIVE_COURSE_CLONE', () => {
    const initialState = { title: 'old title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_COURSE_CLONE,
      data: { course: { title: 'clone course' } }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('clone course');
  });

  it('removes notification from survey notifications array with DISMISS_SURVEY_NOTIFICATION', () => {
    const initialState = {
      survey_notifications: [{ id: 1 }, { id: 2 }, { id: 3 }]
    };
    deepFreeze(initialState);
    const mockedAction = {
      type: DISMISS_SURVEY_NOTIFICATION,
      id: 3
    };

    const newState = course(initialState, mockedAction);
    expect(newState.survey_notifications).to.deep.eq([{ id: 1 }, { id: 2 }]);
  });

  it('toggles boolean of state attribute with TOGGLE_EDITING_SYLLABUS', () => {
    const initialState = { title: 'title', editingSyllabus: true };
    deepFreeze(initialState);
    const mockedAction = {
      type: TOGGLE_EDITING_SYLLABUS
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('title');
    expect(newState.editingSyllabus).to.eq(false);
  });

  it('sets state attribute with START_SYLLABUS_UPLOAD', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: START_SYLLABUS_UPLOAD
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('title');
    expect(newState.uploadingSyllabus).to.eq(true);
  });

  it('reset state attributes and returns updated state with response via SYLLABUS UPLOAD SUCCESS ', () => {
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
    expect(newState.title).to.eq('title');
    expect(newState.uploadingSyllabus).to.eq(false);
    expect(newState.editingSyllabus).to.eq(false);
    expect(newState.syllabus).to.eq('foobar');
  });

  it('returns state and salesforce attributes LINKED_TO_SALESFORCE', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: LINKED_TO_SALESFORCE,
      data: { flags: true }
    };

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('title');
    expect(newState.flags).to.eq(true);
  });
});
