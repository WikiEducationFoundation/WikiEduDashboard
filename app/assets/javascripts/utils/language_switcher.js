if ($().uls) {
  $('.uls-trigger').uls({
    quickList: ['en', 'es', 'fr'],
    onSelect: (language) => {
      if (window.currentUser.id !== '') {
        $.post(`/update_locale/${language}`, () => {
          location.reload();
        });
      } else {
        window.location = `?locale=${language}`;
      }
    }
  });
}
