import '../testHelper';
import ChatActions from '../../app/assets/javascripts/actions/chat_actions.js';
import ChatStore from '../../app/assets/javascripts/stores/chat_store.js';
import CourseStore from '../../app/assets/javascripts/stores/course_store.js';

import sinon from 'sinon';

describe('ChatActions', () => {
  beforeEach(() => {
    sinon.stub($, "ajax").yieldsTo("success", { auth_token: 'abcde' });
  });
  afterEach(() => {
    $.ajax.restore();
  });

  it('.requestAuthToken sets the auth token', (done) => {
    ChatActions.requestAuthToken().then(() => {
      expect(ChatStore.getAuthToken()).to.be.eq('abcde');
      done();
    });
  });

  it('.enableForCourse sets the course enable_chat flag to true', (done) => {
    ChatActions.enableForCourse().then(() => {
      expect(CourseStore.getCourse().flags.enable_chat).to.be.true;
      done();
    });
  });
});
