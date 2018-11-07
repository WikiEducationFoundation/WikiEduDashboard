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
  LINKED_TO_SALESFORCE
} from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('course reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const expectedState = {
      title: '',
      description: '',
      school: '',
      term: '',
      level: '',
      subject: '',
      expected_students: '0',
      start: null,
      end: null,
      timeline_start: null,
      timeline_end: null,
      day_exceptions: '',
      weekdays: '0000000',
      editingSyllabus: false
    };

    const newState = course(undefined, { type: null });
    expect(newState).to.deep.eq(expectedState);
  });

  it('receives a course via RECEIVE_COURSE', () => {
    const initialState = {};
    const mockedAction = {
      type: RECEIVE_COURSE,
      data: { course: { title: 'title' } }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq(mockedAction.data.course);
  });

  it('receives a course update via RECEIVE_COURSE_UPDATE with newStats', () => {
    const initialState = {};
    const mockedAction = {
      type: RECEIVE_COURSE_UPDATE,
      data: { course: { title: 'title' } }
    };
    deepFreeze(initialState);

    /*    const newStats = [
      'createdCount',
      'editedCount',
      'editCount',
      'studentCount',
      'wordCount',
      'viewCount',
      'uploadCount'
    ]; */

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.deep.eq(mockedAction.data.course.title);

    Object.keys(newState.newStats).forEach((key) => {
      expect(newState.newStats[key]).to.eq(false);
    });
  });

  it('persists course via PERSISTED_COURSE', () => {
    const initialState = { description: 'initial description' };
    const mockedAction = {
      type: PERSISTED_COURSE,
      data: { course: { title: 'new title' } }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({
      description: 'initial description',
      title: 'new title'
    });
  });

  it('updates an attribute via UPDATE_COURSE', () => {
    const initialState = { title: 'old title', term: 'old term' };
    const mockedAction = {
      type: UPDATE_COURSE,
      course: { title: 'new title' }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'new title', term: 'old term' });
  });

  it('creates course via CREATED_COURSE', () => {
    const initialState = {};
    const mockedAction = {
      type: CREATED_COURSE,
      data: { course: { title: 'title' } }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState.title).to.eq('title');
  });

  it('receives new state with initial campaign via RECEIVE_INITIAL_CAMPAIGN', () => {
    const initialState = {};
    const campaign = {
      id: 2,
      title: 'title',
      template_description: 'description',
      default_course_type: 'foobar',
      default_passcode: 'pass'
    };
    const mockedAction = {
      type: RECEIVE_INITIAL_CAMPAIGN,
      data: { campaign: campaign }
    };
    deepFreeze(initialState);

    const expectedState = {
      ...initialState,
      initial_campaign_id: campaign.id,
      initial_campaign_title: campaign.title,
      description: campaign.template_description,
      type: campaign.default_course_type,
      passcode: campaign.default_passcode
    };
    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq(expectedState);
  });

  it('should add and delete campaing via ADD_CAMPAIN and DELETE_CAMPAIGN', () => {
    const initialState = { title: 'old title' };
    const mockedAction = {
      type: ADD_CAMPAIGN,
      data: { course: { published: true } }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'old title', published: true });
  });

  it('should receive a course clone via RECEIVE_COURSE_CLONE', () => {
    const initialState = { title: 'old title' };
    const mockedAction = {
      type: RECEIVE_COURSE_CLONE,
      data: { course: { title: 'clone course' } }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'clone course' });
  });

  it('dismisses survey notification via DISMISS_SURVEY_NOTIFICATION', () => {
    const initialState = {
      survey_notifications: [{ id: 1 }, { id: 2 }, { id: 3 }]
    };
    const mockedAction = {
      type: DISMISS_SURVEY_NOTIFICATION,
      id: 3
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState.survey_notifications).to.deep.eq([{ id: 1 }, { id: 2 }]);
  });

  it('toggles editing syllabus via TOGGLE_EDITING_SYLLABUS', () => {
    const initialState = { title: 'title', editingSyllabus: true };
    const mockedAction = {
      type: TOGGLE_EDITING_SYLLABUS
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'title', editingSyllabus: false });
  });

  it('starts syllabus upload via START_SYLLABUS_UPLOAD', () => {
    const initialState = { title: 'title' };
    const mockedAction = {
      type: START_SYLLABUS_UPLOAD
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'title', uploadingSyllabus: true });
  });

  it('has an SYLLABUS UPLOAD SUCCESS ', () => {
    const initialState = { title: 'title' };
    const mockedAction = {
      type: SYLLABUS_UPLOAD_SUCCESS,
      syllabus: 'foobar'
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({
      title: 'title',
      uploadingSyllabus: false,
      editingSyllabus: false,
      syllabus: 'foobar'
    });
  });

  it('should return state and flags via LINKED_TO_SALESFORCE', () => {
    const initialState = { title: 'title' };
    const mockedAction = {
      type: LINKED_TO_SALESFORCE,
      data: { flags: true }
    };
    deepFreeze(initialState);

    const newState = course(initialState, mockedAction);
    expect(newState).to.deep.eq({ title: 'title', flags: true });
  });
});
