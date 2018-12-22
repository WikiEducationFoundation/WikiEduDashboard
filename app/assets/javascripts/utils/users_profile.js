// jQuery for user profile pages
import jQuery from 'jquery';

jQuery(() => {
  let stickyHeaderTop = 0;
  if (jQuery('#profile').length !== 0) {
    // Check the initial Poistion of the Sticky Header
    stickyHeaderTop = jQuery('#profile').offset().top;
    const navbarHeight = jQuery('#userprofile_navbar').height();
    // making the navbar stick when scrolled
    jQuery(window).scroll(() => {
      if (jQuery(window).scrollTop() >= stickyHeaderTop) {
        jQuery('#userprofile_navbar').css({
          position: 'fixed', top: '50px', 'z-index': 1, width: '100%', right: 0
        });
        jQuery('#highlight').css({ display: 'unset' });
      } else {
        jQuery('#userprofile_navbar').css({ position: 'static', top: 'stickyHeaderTop' });
        jQuery('#highlight').css({ display: 'none' });
      }
    });
    jQuery('.profile_container #userprofile_navbar li a').on('click', function () {
      const id = this.hash;
      jQuery('html, body').animate({
        scrollTop: jQuery(id).offset().top - navbarHeight
      }, 500);
    });
  }
});
