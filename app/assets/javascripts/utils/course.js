const List = window.List;
$(() => {
  // Find tables with rows with data-link attribute, then make them clickable
  $('tr[data-link]').on('click', e => {
    // skip if a button was clicked (used for other actions)
    if (e.target.tagName === 'BUTTON') return;

    const loc = e.currentTarget.dataset.link;
    if (e.metaKey || (window.navigator.platform.toLowerCase().indexOf('win') !== -1 && e.ctrlKey)) {
      window.open(loc, '_blank');
    } else {
      window.location = loc;
    }
    return false;
  });

  // Course sorting
  // only sort if there are tables to sort
  let courseList;
  if ($('#courses table').length) {
    courseList = new List('courses', {
      page: 500,
      valueNames: [
        'title', 'revisions', 'characters', 'average-words', 'views', 'students', 'creation-date', 'untrained'
      ]
    });
  }

  // Campaign sorting
  // only sort if there are tables to sort
  let campaignList;
  if ($('#campaigns table').length) {
    campaignList = new List('campaigns', {
      page: 500,
      valueNames: [
        'title', 'num-courses', 'articles-created', 'characters', 'views', 'students', 'creation-date'
      ]
    });
  }

  // for use on campaign/programs page
  $('.remove-course').on('click', e => {
    const confirmed = window.confirm(I18n.t('campaign.confirm_course_removal', {
      title: e.target.dataset.title,
      campaign_title: e.target.dataset.campaignTitle
    }));
    if (!confirmed) {
      e.preventDefault();
    }
  });

  return $('select.sorts').on('change', function () {
    const list = (() => {
      switch ($(this).attr('rel')) {
        case 'courses': return courseList;
        case 'campaigns': return campaignList;
        default: break;
      } })();
    if (list) {
      return list.sort($(this).val(), {
        order: $(this).children('option:selected').attr('rel')
      });
    }
  });
});
