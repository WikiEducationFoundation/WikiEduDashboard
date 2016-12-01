$(() => {
  $('.campaign-delete').on('submit', e => {
    const title = prompt(I18n.t('campaign.confirm_campaign_deletion', { title: e.target.dataset.title }));
    if (title !== e.target.dataset.title) {
      if (title !== null) {
        alert(I18n.t('campaign.confirm_campaign_deletion_failed', { title }));
      }
      e.preventDefault();
    }
  });

  $('.campaign-details').on('editable:edit', e => {
    const $popContainer = $(e.target).find('.pop__container');
    const $popButton = $(e.target).find('.plus');

    // add listener to show/hide the popup, removing any existing listener
    $popButton.show().off('click').on('click', () => {
      $popContainer.find('.pop').toggleClass('open');

      // allow popup to be closed when clicking outside the popup, again removing any existing listener
      $(document).off('click.campaign-popover').on('click.campaign-popover', cp => {
        if (!$(cp.target).parents('.pop__container').length) {
          $popContainer.find('.pop').removeClass('open');
        }
      });
    });
  });

  // close out the popup and hide pop button if existing edit mode
  $('.campaign-details').on('editable:read', e => {
    $(e.target).find('.plus').hide();
    $(e.target).find('.pop__container').removeClass('open');
  });
});
