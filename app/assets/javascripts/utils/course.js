const { List } = window;
document.onreadystatechange = () => {
  if (document.readyState === 'complete') {
    // Find tables with rows with data-link attribute, then make them clickable
    document.querySelector('tr[data-link]')?.addEventListener('click', (e) => {
      // skip if a button was clicked (used for other actions)
      if (e.target.tagName === 'BUTTON') return;

      const loc = e.currentTarget.dataset.link;
      if (e.metaKey || (window.navigator.userAgentData.platform.toLowerCase().indexOf('win') !== -1 && e.ctrlKey)) {
      window.open(loc, '_blank');
      } else {
        window.location = loc;
      }
      return false;
    });
  }
  // Course sorting
  // only sort if there are tables to sort
  let courseList;
  if (document.querySelectorAll('#courses table').length) {
    courseList = new List('courses', {
      page: 500,
      valueNames: [
        'title', 'school', 'revisions', 'characters', 'references', 'average-words', 'views',
        'reviewed', 'students', 'creation-date', 'ungreeted', 'untrained'
      ]
    });
  }

  // Course Results sorting
  // only sort if there are tables to sort
  let courseResultList;
  if (document.querySelectorAll('#course_results table').length) {
    courseResultList = new List('course_results', {
      page: 500,
      valueNames: [
        'title', 'school', 'revisions', 'characters', 'references', 'average-words', 'views',
        'reviewed', 'students', 'creation-date', 'ungreeted', 'untrained'
      ]
    });
  }

  // Campaign sorting
  // only sort if there are tables to sort
  let campaignList;
  if (document.querySelectorAll('#campaigns table').length) {
    campaignList = new List('campaigns', {
      page: 500,
      valueNames: [
        'title', 'num-courses', 'articles-created', 'articles-edited', 'characters', 'references', 'views', 'students', 'creation-date'
      ]
    });
  }

  // Article sorting
  // only sort if there are tables to sort
  let articlesList;
  if (document.querySelectorAll('#campaign-articles table').length) {
    articlesList = new List('campaign-articles', {
      page: 10000,
      valueNames: [
        'title', 'views', 'char_added', 'references', 'lang_project', 'course_title'
      ]
    });
  }

  // Student sorting
  // only sort if there are tables to sort
  let studentsList;
  if (document.querySelectorAll('#users table').length) {
    studentsList = new List('users', {
      page: 10000,
      valueNames: [
        'username', 'revision-count', 'title'
      ]
    });
  }

  // for use on campaign/programs page
  const removeCourseBtn = document.querySelectorAll('.remove-course');
  for (let i = 0; i < removeCourseBtn.length; i += 1) {
    removeCourseBtn[i]?.addEventListener('click', (e) => {
        const confirmed = window.confirm(I18n.t('campaign.confirm_course_removal', {
          title: e.target.dataset.title,
          campaign_title: e.target.dataset.campaignTitle
        }));
        if (!confirmed) {
          e.preventDefault();
        }
    });
  }

  const deleteCourseBtn = document.getElementsByClassName('delete-course-from-campaign')[0];
  if (deleteCourseBtn) {
    deleteCourseBtn.addEventListener('click', (e) => {
      const enteredTitle = window.prompt(I18n.t('courses.confirm_course_deletion', { title: e.target.dataset.title }));
      if (!enteredTitle) {
        e.preventDefault();
      } else if (enteredTitle.trim() !== e.target.dataset.title.trim()) {
        e.preventDefault();
        alert(I18n.t('courses.confirm_course_deletion_failed', { title: enteredTitle }));
      }
   });
}

  return document.querySelectorAll('select.sorts').forEach(item => item?.addEventListener('change', function () {
    const list = (() => {
      switch (this.getAttribute('rel')) {
        case 'courses': return courseList;
        case 'course_results': return courseResultList;
        case 'campaigns': return campaignList;
        case 'campaign-articles': return articlesList;
        case 'users': return studentsList;
        default: break;
      }
  })();
  if (list) {
    return list.sort(this?.value, {
      order: this.options[this.selectedIndex].getAttribute('rel')
    });
    }
  }));
};
