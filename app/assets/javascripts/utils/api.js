import { capitalize } from './strings';
import logErrorMessage from './log_error_message';
import request from './request';
import { stringify } from 'query-string';

const SentryLogger = {};

/* eslint-disable */
const API = {
  // /////////
  // Getters /
  // /////////
  fetchFeedback(articleTitle, assignmentId) {
    return request(`/revision_feedback.json?title=${articleTitle}&assignment_id=${assignmentId}`)
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

  async createCustomFeedback(assignmentId, text, userId) {
    const response = await request(`/assignments/${assignmentId}/assignment_suggestions`, {
      method: 'POST',
      body: JSON.stringify({ feedback: { text: text, assignment_id: assignmentId, user_id: userId } })
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async destroyCustomFeedback(assignmentId, id) {
    const response = await request(`/assignments/${assignmentId}/assignment_suggestions/${id}`, {
      method: 'DELETE',
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchUserProfileStats(username) {
    const response = await request(`/user_stats.json?username=${username}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async updateArticleTrackedStatus(article_id, course_id, tracked) {
    const params = {
      article_id,course_id, tracked
    }
    const response = await request(`/articles/status.json?${stringify(params)}`, {
      method: 'POST'
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchArticleDetails(articleId, courseId) {
    const response = await request(`/articles/details.json?article_id=${articleId}&course_id=${courseId}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchDykArticles(opts = {}) {
    const response = await request(`/revision_analytics/dyk_eligible.json?scoped=${opts.scoped || false}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchSuspectedPlagiarism(opts = {}) {
    const response = await request(`/revision_analytics/suspected_plagiarism.json?scoped=${opts.scoped || false}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchSuspectedCoursePlagiarism(course_id) {
    const response = await request(`/courses/${course_id}/suspected_plagiarism.json`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchRecentUploads(opts = {}) {
    const response = await request(`/revision_analytics/recent_uploads.json?scoped=${opts.scoped || false}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async cloneCourse(id, campaign) {
    const campaignQueryParam = campaign ? `?campaign_slug=${campaign}` : ''
    const response = await request(`/clone_course/${id}${campaignQueryParam}`, {
      method: 'POST'
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async fetchUserCourses(userId) {
    const response = await request(`/courses_users.json?user_id=${userId}`);

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async deleteAssignment(assignment) {
    const queryString = $.param(assignment);
    const response = await request(`/assignments/${assignment.id}?${queryString}`, {
      method: 'DELETE'
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async createAssignment(opts) {
    const queryString = $.param(opts);
    const response = await request(`/assignments.json?${queryString}`, {
      method: 'POST'
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async createRandomPeerAssignments(opts) {
    const queryString = $.param(opts);
    const response = await request(`/assignments/assign_reviewers_randomly?${queryString}`, {
      method: 'POST'
    });

    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
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
      SentryLogger.type = 'POST';

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
          SentryLogger.obj = this.obj;
          SentryLogger.status = this.status;
          Sentry.captureMessage('saveTimeline failed', {
            level: 'error',
            extra: SentryLogger
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
    SentryLogger.type = type;
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
          SentryLogger.obj = this.obj;
          SentryLogger.status = this.status;
          Sentry.captureMessage('saveCourse failed', {
            level: 'error',
            extra: SentryLogger
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

  async deleteBlock(block_id) {
    const response = await request(`/blocks/${block_id}.json`, {
      method: 'DELETE'
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return {block_id};
  },

  async deleteWeek(week_id) {
    const response = await request(`/weeks/${week_id}.json`, {
      method: 'DELETE'
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return { week_id };
  },

  async deleteAllWeeks(course_id) {
    const response = await request(`/courses/${course_id}/delete_all_weeks.json`, {
      method: 'DELETE'
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async notifyOverdue(courseSlug) {
    const response = await request(`/courses/${courseSlug}/notify_untrained.json`);
    if (!response.ok) {
      logErrorMessage(response, 'Couldn\'t notify students! ');
      const data = await response.json();
      throw data;
    }
    alert('Students with overdue trainings notified!');
    return response.json();
  },

  async greetStudents(courseId) {
    const response = await request(`/greeting?course_id=${courseId}`, {
      method: 'PUT',
    });
    if (!response.ok) {
      logErrorMessage(response, 'There was an error with the greetings! ');
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async modify(model, courseSlug, data, add) {
    const verb = add ? 'added' : 'removed';
    const response = await request(`/courses/${courseSlug}/${model}.json`, {
      method: (add ? 'POST' : 'DELETE'),
      body: JSON.stringify(data)
    });
    if (!response.ok) {
      logErrorMessage(response, `${capitalize(model)} not ${verb}: `);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async dismissNotification(id) {
    const response = await request('/survey_notification', {
      method: 'PUT',
      body: JSON.stringify( { survey_notification: { id, dismissed: true } })
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
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

  async createBadWorkAlert(opts) {
    const response = await request('/alerts', {
      method: 'POST',
      body: JSON.stringify( { ...opts, alert_type: 'BadWorkAlert' })
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async createNeedHelpAlert(opts) {
    const response = await request('/alerts', {
      method: 'POST',
      body: JSON.stringify( { ...opts, alert_type: 'NeedHelpAlert' })
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async requestNewAccount(passcode, courseSlug, username, email, createAccountNow) {
    const response = await request('/requested_accounts', {
      method: 'PUT',
      body: JSON.stringify(  
        { passcode, course_slug: courseSlug, username, email, create_account_now: createAccountNow }
      )
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async enableAccountRequests(courseSlug) {
    const response = await request(`/requested_accounts/${courseSlug}/enable_account_requests`);
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async linkToSalesforce(courseId, salesforceId) {
    const response = await request(`/salesforce/link/${courseId}.json?salesforce_id=${salesforceId}`, {
      method: 'PUT'
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async updateSalesforceRecord(courseId) {
    const response = await request(`/salesforce/update/${courseId}.json`, {
      method: 'PUT'
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },
};

export default API;
