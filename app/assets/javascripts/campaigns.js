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

    // campaign details form submission
    $('.campaign-details .rails_editable-save').on('click', () => {
      $('#edit_campaign_details').trigger('submit');
    });
  });

  // close out the popup and hide pop button if existing edit mode
  $('.campaign-details').on('editable:read', e => {
    $(e.target).find('.plus').hide();
    $(e.target).find('.pop__container').removeClass('open');
  });

  $('.remove-organizer-form').on('submit', e => {
    if (!confirm(I18n.t('users.remove_confirmation', { username: e.target.dataset.username }))) {
      e.preventDefault();
    }
  });

  $('#use_dates').on('change', e => {
    $('.campaign-dates').toggleClass('hidden', !e.target.checked);
    if (e.target.checked) {
      $('#campaign_start').val('');
      $('#campaign_end').val('');
    }
  });
});
