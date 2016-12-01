import { capitalize } from './strings';

/* eslint-disable */
let logErrorMessage = function(obj, prefix) {
  // readyState 0 usually indicates that the user navigated away before ajax
  // requests resolved.
  if (obj.readyState === 0) { return; }
  let message = prefix || 'Error: ';
  message += (obj.responseJSON && obj.responseJSON.message) || obj.statusText;
  return console.log(message);
};

let RavenLogger = {};

const API = {
  //##########
  // Getters #
  //##########
  fetchLookups(model) {
    return new Promise((res, rej) => {
      return $.ajax({
        type: 'GET',
        url: `/lookups/${model}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
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
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRevisions(studentId, courseId) {
    return new Promise(function(res, rej) {
      let url = `/revisions.json?user_id=${studentId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchTrainingStatus(studentId, courseId) {
    return new Promise(function(res, rej) {
      let url = `/training_status.json?user_id=${studentId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchArticleDetails(articleId, courseId) {
    return new Promise(function(res, rej) {
      let url = `/articles/details.json?article_id=${articleId}&course_id=${courseId}`;
      return $.ajax({
        type: 'GET',
        url,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  fetchDykArticles(opts={}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/dyk_eligible.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchSuspectedPlagiarism(opts={}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/suspected_plagiarism.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRecentEdits(opts={}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/recent_edits.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchRecentUploads(opts={}) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/recent_uploads.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
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
          console.log('Received course clone');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchCampaigns() {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: '/campaigns.json',
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchWizardPanels(wizard_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/wizards/${wizard_id}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
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
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  deleteAssignment(assignment) {
    let queryString = $.param(assignment);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/assignments/${assignment.assignment_id}?${queryString}`,
        success(data) {
          console.log('Deleted assignment');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  createAssignment(opts) {
    let queryString = $.param(opts);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/assignments.json?${queryString}`,
        success(data) {
          console.log('Created assignment');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  updateAssignment(opts) {
    let queryString = $.param(opts);
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: `/assignments/${opts.id}.json?${queryString}`,
        success(data) {
          console.log('Updated assignment');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },


  fetch(course_id, endpoint) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${course_id}/${endpoint}.json`,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  fetchAllTrainingModules(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: "/training_modules.json",
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
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
      .fail(function(obj, status) {
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
          console.log('Slide completed');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  //##########
  // Setters #
  //##########
  saveTimeline(course_id, data) {
    let promise = new Promise(function(res, rej) {
      let cleanup = array =>
        (() => {
          let result = [];
          for (let obj of array) {
            let item;
            if (obj.is_new) {
              delete obj.id;
              item = delete obj.is_new;
            }
            result.push(item);
          }
          return result;
        })()
      ;

      let { weeks } = data;
      let { blocks } = data;
      let { gradeables } = data;

      for (let week of weeks) {
        week.blocks = [];
        for (let block of blocks) {
          if (block.week_id === week.id) { week.blocks.push(block); }
          for (let gradeable of gradeables) {
            if (gradeable.gradeable_item_id === block.id) {
              block.gradeable = gradeable;
              if (block.is_new) { delete gradeable.gradeable_item_id; }
            }
          }
        }
      }

      cleanup(weeks);
      cleanup(blocks);
      cleanup(gradeables);

      let req_data = {weeks};
      RavenLogger['type'] = 'POST';

      return $.ajax({
        type: 'POST',
        url: `/courses/${course_id}/timeline.json`,
        contentType: 'application/json',
        data: JSON.stringify(req_data),
        success(data) {
          console.log('Saved timeline!');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        this.obj = obj;
        this.status = status;
        console.error('Couldn\'t save timeline!');
        RavenLogger['obj'] = this.obj;
        RavenLogger['status'] = this.status;
        Raven.captureMessage('saveTimeline failed', {
                             level: 'error',
                             extra: RavenLogger
                           });
        return rej(obj);
      });
    });
    return promise;
  },
  saveGradeables(course_id, data) {
    return new Promise(function(res, rej) {
      let cleanup = array =>
        (() => {
          let result = [];
          for (let obj of array) {
            let item;
            if (obj.is_new) {
              delete obj.id;
              item = delete obj.is_new;
            }
            result.push(item);
          }
          return result;
        })()
      ;

      let { gradeables } = data;
      cleanup(gradeables);

      return $.ajax({
        type: 'POST',
        url: `/courses/${course_id}/gradeables.json`,
        contentType: 'application/json',
        data: JSON.stringify({
          gradeables}),
        success(data) {
          console.log('Saved gradeables!');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        console.error('Couldn\'t save gradeables!');
        return rej(obj);
      });
    });
  },
  saveCourse(data, course_id=null) {
    console.log("API: saveCourse");
    let append = (course_id != null) ? `/${course_id}` : '';
    // append += '.json'
    let type = (course_id != null) ? 'PUT' : 'POST';
    RavenLogger['type'] = type;
    let req_data = {course: data.course};

    this.obj = null;
    this.status = null;
    let promise = new Promise((res, rej) =>
      $.ajax({
        type,
        url: `/courses${append}.json`,
        contentType: 'application/json',
        data: JSON.stringify(req_data),
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        this.obj = obj;
        this.status = status;
        console.error('Couldn\'t save course!');
        RavenLogger['obj'] = this.obj;
        RavenLogger['status'] = this.status;
        Raven.captureMessage('saveCourse failed', {
                             level: 'error',
                             extra: RavenLogger
                           });
        return rej(obj);
      })
    );

    return promise;
  },

  deleteCourse(course_id) {
    return $.ajax({
      type: 'DELETE',
      url: `/courses/${course_id}.json`,
      success(data) {
        return window.location = '/';
      }
    })
    .fail((obj, status) => console.error('Couldn\'t delete course'));
  },

  deleteBlock(block_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'DELETE',
        url: `/blocks/${block_id}.json`,
        success(data) {
          return res({block_id});
        }
      })
      .fail(function(obj, status) {
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
          return res({week_id});
        }
      })
      .fail(function(obj, status) {
          console.error('Couldn\'t delete week');
          return rej(obj);
      })
    );
  },

  needsUpdate(course_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${course_id}/needs_update.json`,
        success(data) {
          alert(data.result);
          return res(data);
        }
      })
      .fail(function(obj, status) {
        console.error('Couldn\'t request update');
        return rej(obj);
      })
    );
  },

  notifyOverdue(course_id) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/courses/${course_id}/notify_untrained.json`,
        success(data) {
          alert('Students with overdue trainings notified!');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj, 'Couldn\'t notify students! ');
        return rej(obj);
      })
    );
  },

  submitWizard(course_id, wizard_id, data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: `/courses/${course_id}/wizard/${wizard_id}.json`,
        contentType: 'application/json',
        data: JSON.stringify({
          wizard_output: data}),
        success(data) {
          console.log('Submitted the wizard answers!');
          return res(data);
        }
      })
      .fail(function(obj, status) {
        getErrorMessage(obj, 'Couldn\'t submit wizard answers! ');
        return rej(obj);
      })
    );
  },

  modify(model, course_id, data, add) {
    let verb = add ? 'added' : 'removed';
    return new Promise((res, rej) =>
      $.ajax({
        type: (add ? 'POST' : 'DELETE'),
        url: `/courses/${course_id}/${model}.json`,
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          console.log((capitalize(verb) + ' ' + model));
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj, `${capitalize(model)} not ${verb}: `);
        return rej(obj);
      })
    );
  },

  onboard(data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: "/onboarding/onboard",
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
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
        data: { survey_notification: { id, dismissed: true }  },
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  uploadSyllabus({ courseId, file }) {
    return new Promise(function(res, rej) {
      let data = new FormData();
      data.append("syllabus", file);
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
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      });
    });
  },

  createNeedHelpAlert(opts) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'POST',
        url: "/alerts",
        data: opts,
        success(data) {
          return res(data);
        }
      })
      .fail(function(obj, status) {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  }
};

export default API;
