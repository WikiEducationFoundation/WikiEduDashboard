
//watch data change on stats overview
//load spineer for 2 sec before showing data
$('.stat-display__value').each(function () {
    target = this;

    observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        const id = mutation.target.id;
        const parent = $(`#${id}`).closest('.stat-display__stat').attr('id');
        $(`#${id}`).addClass('hide');
        $(`#${parent} .spinner`).removeClass('hide');
        setTimeout(() => {
          $(`#${id}`).removeClass('hide');
          $(`#${parent} .spinner`).addClass('hide');
        }, 2000);
      });
    });

    observer.observe(target, { childList: true, characterData: true, subtree: true });
  });
