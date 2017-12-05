// jQuery for user profile pages
$(() => {
  let stickyHeaderTop = 0;
  if ($('#profile').length !== 0) {
    // Check the initial Poistion of the Sticky Header
    stickyHeaderTop = $('#profile').offset().top;
    const navbarHeight = $('#userprofile_navbar').height();
    // making the navbar stick when scrolled
    $(window).scroll(() => {
      if ($(window).scrollTop() >= stickyHeaderTop) {
        $('#userprofile_navbar').css({
          position: 'fixed', top: '50px', 'z-index': 1, width: '100%', right: 0
        });
        $('#highlight').css({ display: 'unset' });
      }
      else {
        $('#userprofile_navbar').css({ position: 'static', top: 'stickyHeaderTop' });
        $('#highlight').css({ display: 'none' });
      }
    });
    $('.profile_container #userprofile_navbar li a').on("click", function () {
      const id = this.hash;
      $('html, body').animate({
        scrollTop: $(id).offset().top - navbarHeight
      }, 500);
    });
  }
});
