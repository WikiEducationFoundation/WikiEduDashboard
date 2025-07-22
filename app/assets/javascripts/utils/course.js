const { List } = window;
document.onreadystatechange = () => {
  if (document.readyState === 'complete') {
    // Find tables with rows with data-link attribute, then make them clickable
    document.querySelector('tr[data-link]')?.addEventListener('click', (e) => {
      // skip if a button was clicked (used for other actions)
      if (e.target.tagName === 'BUTTON') return;

      const loc = e.currentTarget.dataset.link;
      if (e.metaKey || (window.navigator.userAgentData?.platform?.toLowerCase().includes('win') && e.ctrlKey)) {
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
  if (isTableValid('#courses')) {
    courseList = new List('courses', {
      page: 500,
      valueNames: [
        'title', 'school', 'revisions', 'characters', 'references', 'average-words', 'views',
        'reviewed', 'students', 'creation-date', 'ungreeted', 'untrained', 'start-date'
      ]
    });
  }

  // Course Results sorting
  // only sort if there are tables to sort
  let courseResultList;
  if (isTableValid('#course_results')) {
    courseResultList = new List('course_results', {
      page: 500,
      valueNames: [
        'title', 'school', 'revisions', 'characters', 'references', 'average-words', 'views',
        'reviewed', 'students', 'creation-date', 'ungreeted', 'untrained', 'start-date'
      ]
    });
  }

  // Campaign sorting
  // only sort if there are tables to sort
  let campaignList;
  if (isTableValid('#campaigns')) {
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
  if (isTableValid('#campaign-articles')) {
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
  if (isTableValid('#users')) {
    studentsList = new List('users', {
      page: 10000,
      valueNames: [
        'username', 'revision-count', 'title'
      ]
    });
  }

  function isTableValid(selector) {
    const tables = document.querySelectorAll(`${selector} table`);
    if (tables.length === 0) return false;

    let isValid = false;
    tables.forEach((table) => {
      const tbody = table.querySelector('tbody');
      if (tbody && tbody.children.length > 0) {
        isValid = true;
      }
    });
    return isValid;
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
