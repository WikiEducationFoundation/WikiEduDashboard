import _ from 'lodash';
import { capitalize } from './strings';
import logErrorMessage from './log_error_message';

const RavenLogger = {};

/* eslint-disable */
const API = {
  // /////////
  // Getters /
  // /////////
  fetchLookups(model) {
    return new Promise((res, rej) => {
      return $.ajax({
        type: 'GET',
        url: `/lookups/${model}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    }
    );
  },

  fetchWizardIndex() {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: '/wizards.json',
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRevisions(studentId, courseId) {
    return new Promise((res, rej) => {
      const url = `/revisions.json?user_id=${studentId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchCourseRevisions(courseId, limit) {
    return new Promise((res, rej) => {
      const url = `/courses/${courseId}/revisions.json?limit=${limit}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchFeedback(articleTitle, assignmentId) {
    return new Promise((res, rej) => {
      const url = `/revision_feedback?title=${articleTitle}&assignment_id=${assignmentId}`;
      return $.ajax({
        type: 'GET',
        url,
        dataType: 'json',
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  postFeedbackFormResponse(subject, body) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/feedback_form_responses`,
        data: {feedback_form_response: {subject: subject, body: body}},
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  createCustomFeedback(assignmentId, text, userId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/assignments/${assignmentId}/assignment_suggestions`,
        data: {feedback: {text: text, assignment_id: assignmentId, user_id: userId}},
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  destroyCustomFeedback(assignmentId, id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/assignments/${assignmentId}/assignment_suggestions/${id}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchTrainingStatus(studentId, courseId) {
    return new Promise((res, rej) => {
      const url = `/training_status.json?user_id=${studentId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchUserProfileStats(username){
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/user_stats.json?username=${ username }`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchArticleDetails(articleId, courseId) {
    return new Promise((res, rej) => {
      const url = `/articles/details.json?article_id=${articleId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchDykArticles(opts = {}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/dyk_eligible.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchSuspectedPlagiarism(opts = {}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/suspected_plagiarism.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRecentEdits(opts = {}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/recent_edits.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRecentUploads(opts = {}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/recent_uploads.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  cloneCourse(id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/clone_course/${id}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchWizardPanels(wizardId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/wizards/${wizardId}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchUserCourses(userId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses_users.json?user_id=${userId}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  deleteAssignment(assignment) {
    const queryString = $.param(assignment);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/assignments/${assignment.assignment_id}?${queryString}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  createAssignment(opts) {
    const queryString = $.param(opts);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/assignments.json?${queryString}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  updateAssignment(opts) {
    const queryString = $.param(opts);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/assignments/${opts.id}.json?${queryString}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetch(courseId, endpoint) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${courseId}/${endpoint}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchAllTrainingModules() {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: '/training_modules.json',
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchTrainingModule(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/training_module.json?module_id=${opts.module_id}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  setSlideCompleted(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/training_modules_users.json?\
module_id=${opts.module_id}&\
user_id=${opts.user_id}&\
slide_id=${opts.slide_id}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  // /////////
  // Setters #
  // /////////
  saveTimeline(courseId, data) {
    const promise = new Promise((res, rej) => {
      const cleanup = function (array) {
        const result = [];
        _.forEach(array, (obj) => {
          let item;
          if (obj.is_new) {
            delete obj.id;
            item = delete obj.is_new;
          }
          result.push(item);
        });
        return result;
      }

      const { weeks } = data;
      const { blocks } = data;
      const { gradeables } = data;

      _.forEach(weeks, (week) => {
        week.blocks = [];
        _.forEach(blocks, (block) => {
          if (block.week_id === week.id) { week.blocks.push(block); }
          _.forEach(gradeables, (gradeable) => {
            if (gradeable.gradeable_item_id === block.id) {
              block.gradeable = gradeable;
              if (block.is_new) { delete gradeable.gradeable_item_id; }
            }
          });
        });
      });

      cleanup(weeks);
      cleanup(blocks);
      cleanup(gradeables);

      const req_data = { weeks };
      RavenLogger.type = 'POST';

      return $.ajax({
        type: 'POST',
        url: `/courses/${courseId}/timeline.json`,
        contentType: 'application/json',
        data: JSON.stringify(req_data),
        success(data) {
          return res(data);
        }
      })
      .fail(function (obj, status) {
        this.obj = obj;
        this.status = status;
        console.error('Couldn\'t save timeline!');
        RavenLogger.obj = this.obj;
        RavenLogger.status = this.status;
        Raven.captureMessage('saveTimeline failed', {
          level: 'error',
          extra: RavenLogger
        });
        return rej(obj);
      });
    });
    return promise;
  },

  saveCourse(data, courseId = null) {
    const append = (courseId != null) ? `/${courseId}` : '';
    // append += '.json'
    const type = (courseId != null) ? 'PUT' : 'POST';
    RavenLogger.type = type;
    let req_data = { course: data.course };

    this.obj = null;
    this.status = null;
    const promise = new Promise((res, rej) =>
      $.ajax({
        type,
        url: `/courses${append}.json`,
        contentType: 'application/json',
        data: JSON.stringify(req_data),
        success(data) {
          return res(data);
        }
      })
      .fail(function (obj, status) {
        this.obj = obj;
        this.status = status;
        console.error('Couldn\'t save course!');
        RavenLogger.obj = this.obj;
        RavenLogger.status = this.status;
        Raven.captureMessage('saveCourse failed', {
          level: 'error',
          extra: RavenLogger
        });
        return rej(obj);
      })
    );

    return promise;
  },

  deleteCourse(courseId) {
    return $.ajax({
      type: 'DELETE',
      url: `/courses/${courseId}.json`,
      success(data) {
        return window.location = '/';
      }
    })
    .fail(() => console.error('Couldn\'t delete course'));
  },

  deleteBlock(block_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/blocks/${block_id}.json`,
        success(data) {
          return res({ block_id });
        }
      })
      .fail((obj) => {
        console.error('Couldn\'t delete block');
        return rej(obj);
      })
    );
  },

  deleteWeek(week_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/weeks/${week_id}.json`,
        success(data) {
          return res({ week_id });
        }
      })
      .fail((obj) => {
        console.error('Couldn\'t delete week');
        return rej(obj);
      })
    );
  },

  deleteAllWeeks(course_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/courses/${course_id}/delete_all_weeks.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        console.error('Couldn\'t delete all weeks');
        return rej(obj);
      })
    );
  },

  needsUpdate(courseId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${courseId}/needs_update.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        console.error('Couldn\'t request update');
        rej(obj);
      })
    );
  },

  notifyOverdue(courseId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${courseId}/notify_untrained.json`,
        success(data) {
          alert('Students with overdue trainings notified!');
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj, 'Couldn\'t notify students! ');
        return rej(obj);
      })
    );
  },

  greetStudents(courseId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/greeting?course_id=${courseId}`,
        success(data) {
          alert('Student greetings added to the queue.');
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj, 'There was an error with the greetings! ');
        return rej(obj);
      })
    );
  },

  submitWizard(courseId, wizardId, data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/courses/${courseId}/wizard/${wizardId}.json`,
        contentType: 'application/json',
        data: JSON.stringify({ wizard_output: data }),
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj, 'Couldn\'t submit wizard answers! ');
        return rej(obj);
      })
    );
  },

  modify(model, courseId, data, add) {
    const verb = add ? 'added' : 'removed';
    return new Promise((res, rej) =>
      $.ajax({
        type: (add ? 'POST' : 'DELETE'),
        url: `/courses/${courseId}/${model}.json`,
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj, `${capitalize(model)} not ${verb}: `);
        return rej(obj);
      })
    );
  },

  onboard(data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: '/onboarding/onboard',
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  dismissNotification(id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: '/survey_notification',
        dataType: 'json',
        data: { survey_notification: { id, dismissed: true } },
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  uploadSyllabus({ courseId, file }) {
    return new Promise((res, rej) => {
      const data = new FormData();
      data.append('syllabus', file);
      return $.ajax({
        type: 'POST',
        cache: false,
        url: `/courses/${courseId}/update_syllabus`,
        contentType: false,
        processData: false,
        data,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  createNeedHelpAlert(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: '/alerts',
        data: opts,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  chatLogin() {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: '/chat/login.json',
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  enableChat(courseId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/chat/enable_for_course/${courseId}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  linkToSalesforce(courseId, salesforceId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/salesforce/link/${courseId}.json?salesforce_id=${salesforceId}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  updateSalesforceRecord(courseId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/salesforce/update/${courseId}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  }
};

export default API;
