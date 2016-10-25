const List = window.List;
$(() => {
  // Find tables with rows with data-link attribute, then make them clickable
  $('tr[data-link]').on('click', function (e) {
    const loc = $(this).attr('data-link');
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

  $('select.campaigns').change(() => {
    const campaign = $('select.campaigns option:selected').val();
    return window.location = `/explore?campaign=${encodeURIComponent(campaign)}`;
  });

  return $('select.sorts').change(function () {
    const list = (() => {
      switch ($(this).attr('rel')) {
        case 'courses': return courseList;
        default: break;
      } })();
    if (list) {
      return list.sort($(this).val(), {
        order: $(this).children('option:selected').attr('rel')
      });
    }
  });
});
