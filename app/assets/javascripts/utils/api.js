import { capitalize } from './strings';
import logErrorMessage from './log_error_message';
import request from './request';

const RavenLogger = {};

/* eslint-disable */
const API = {
  // /////////
  // Getters /
  // /////////
  fetchRevisions(studentId, courseId) {
    return request(`/revisions.json?user_id=${studentId}&course_id=${courseId}`)
      .then(res => {
        if (res.ok) {
          return res.json();
        }
        else {
          return Promise.reject({ statusText: res.statusText });
        }
      })
      .catch(error => {
        logErrorMessage(error);
        return Promise.reject({ error });
      });
  },

  fetchCourseRevisions(courseId, limit) {
    return request(`/courses/${courseId}/revisions.json?limit=${limit}`)
      .then(res => {
        if (res.ok) {
          return res.json();
        }
        else {
          return Promise.reject({ statusText: res.statusText });
        }
      })
      .catch(error => {
        logErrorMessage(error);
        return Promise.reject({ error });
      });
  },

  fetchFeedback(articleTitle, assignmentId) {
    return request(`/revision_feedback?title=${articleTitle}&assignment_id=${assignmentId}`)
      .then(res => {
        if (res.ok) {
          return res.json();
        }
        else {
          return Promise.reject({ statusText: res.statusText });
        }
      })
      .catch(error => {
        logErrorMessage(error);
        return Promise.reject({ error });
      });
  },

  postFeedbackFormResponse(subject, body) {
    return request(`/feedback_form_responses`, {
      method: 'POST',
      body: JSON.stringify({ feedback_form_response: { subject: subject, body: body } }),
    })
      .then(res => {
        if (res.ok) {
          return res.json();
        }
        else {
          return Promise.reject({ statusText: res.statusText });
        }
      })
      .catch(error => {
        logErrorMessage(error);
        return Promise.reject({ error });
      });
  },

  createCustomFeedback(assignmentId, text, userId) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/assignments/${assignmentId}/assignment_suggestions`,
        data: { feedback: { text: text, assignment_id: assignmentId, user_id: userId } },
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

  fetchUserProfileStats(username) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/user_stats.json?username=${username}`,
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

  updateArticleTrackedStatus(articleId, courseId, tracked) {
    return new Promise((res, rej) => {
      const url = `/articles/status.json?article_id=${articleId}&tracked=${tracked}&course_id=${courseId}`;
      return $.ajax({
        type: 'POST',
        url,
        success(data) {
          return res(data);
        }
      }).fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
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

  cloneCourse(id, campaign) {
    const campaignQueryParam = campaign ? `?campaign_slug=${campaign}` : ''
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/clone_course/${id}${campaignQueryParam}`,
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
        url: `/assignments/${assignment.id}?${queryString}`,
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
    return request(`/courses/${courseId}/${endpoint}.json`, {
      credentials: "include"
    })
      .then(res => {
        if (res.ok) {
          return res.json();
        }
        else {
          return Promise.reject({ statusText: res.statusText });
        }
      })
      .catch(error => {
        logErrorMessage(error);
        return Promise.reject({ error });
      });
  },



  // /////////
  // Setters #
  // /////////
  saveTimeline(courseId, data) {
    const cleanObject = object => {
      if (object.is_new) {
        delete object.id;
        delete object.is_new;
      }
    };
    const promise = new Promise((res, rej) => {
      const weeks = []
      data.weeks.forEach(week => {
        const cleanWeek = { ...week };
        const cleanBlocks = [];
        cleanWeek.blocks.forEach(block => {
          const cleanBlock = { ...block }
          cleanObject(cleanBlock);
          cleanBlocks.push(cleanBlock);
        });
        cleanWeek.blocks = cleanBlocks;
        cleanObject(cleanWeek);
        weeks.push(cleanWeek);
      });

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
    // append = '.json'
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

  notifyOverdue(courseSlug) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${courseSlug}/notify_untrained.json`,
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

  modify(model, courseSlug, data, add) {
    const verb = add ? 'added' : 'removed';
    return new Promise((res, rej) =>
      $.ajax({
        type: (add ? 'POST' : 'DELETE'),
        url: `/courses/${courseSlug}/${model}.json`,
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
  
  createBadWorkAlert(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: '/alerts',
        data: { ...opts, alert_type: 'BadWorkAlert' },
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

  createNeedHelpAlert(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: '/alerts',
        data: { ...opts, alert_type: 'NeedHelpAlert' },
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

  requestNewAccount(passcode, courseSlug, username, email, createAccountNow) {
    return new Promise((res, rej) => {
      $.ajax({
        type: 'PUT',
        url: '/requested_accounts',
        data: { passcode, course_slug: courseSlug, username, email, create_account_now: createAccountNow },
        success(data) {
          return res(data);
        }
      })
        .fail((obj) => {
          logErrorMessage(obj);
          return rej(obj);
        })
    });
  },

  enableAccountRequests(courseSlug) {
    return new Promise((res, rej) => {
      $.ajax({
        type: 'GET',
        url: `/requested_accounts/${courseSlug}/enable_account_requests`,
        success(data) {
          return res(data);
        }
      })
        .fail((obj) => {
          logErrorMessage(obj);
          return rej(obj);
        })
    });
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
