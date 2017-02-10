// jQuery for making the navbar stick when scrolled
$(() => {
  // Check the initial Poistion of the Sticky Header
  const stickyHeaderTop = $('#userprofile_navbar').offset().top;

  $(window).scroll(() => {
    if ($(window).scrollTop() >= stickyHeaderTop) {
      $('#userprofile_navbar').css({ position: 'fixed', top: '50px', 'z-index': 1, width: '100%' });
      $('#highlight').css({ display: 'unset' });
    }
    else {
      $('#userprofile_navbar').css({ position: 'static', top: 'stickyHeaderTop' });
      $('#highlight').css({ display: 'none' });
    }
  });
});
