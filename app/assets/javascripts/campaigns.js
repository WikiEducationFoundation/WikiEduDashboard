import './utils/editable';

window.onload = () => {
  const createCampaignButton = document.querySelector('.create-campaign-button');
  const createModalWrapper = document.querySelector('.create-modal-wrapper');
  const wizardPanel = document.querySelector('.wizard__panel');

  document.querySelector('.campaign-delete')?.addEventListener('submit', (e) => {
    const title = prompt(I18n.t('campaign.confirm_campaign_deletion', { title: e.target.dataset.title }));
    if (title !== e.target.dataset.title) {
      if (title !== null) {
        alert(I18n.t('campaign.confirm_campaign_deletion_failed', { title }));
      }
      e.preventDefault();
    }
  });

  $('.campaign-details').on('editable:edit', (e) => {
    const $popContainer = $(e.target).find('.pop__container');
    const $popButton = $(e.target).find('.plus');

    // add listener to show/hide the popup, removing any existing listener
    $popButton.show().off('click').on('click', () => {
      $popContainer.find('.pop').toggleClass('open');

      // allow popup to be closed when clicking outside the popup, again removing any existing listener
      $(document).off('click.campaign-popover').on('click.campaign-popover', (cp) => {
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
  $('.campaign-details').on('editable:read', (e) => {
    $(e.target).find('.plus').hide();
    $(e.target).find('.pop__container').removeClass('open');
  });

  document.querySelector('.remove-organizer-form')?.addEventListener('submit', (e) => {
    if (!confirm(I18n.t('users.remove_confirmation', { username: e.target.dataset.username }))) {
      e.preventDefault();
    }
  });

  document.querySelector('#use_dates')?.addEventListener('change', (e) => {
    if (e.target.checked) {
      document.querySelector('.campaign-dates')?.classList.remove('hidden');
    } else {
      document.querySelector('.campaign-dates')?.classList.add('hidden');
      document.querySelector('#campaign_start').value = '';
      document.querySelector('#campaign_end').value = '';
    }
  });

  document.querySelectorAll('.campaign_passcode')?.forEach((radio) => {
    radio.addEventListener('change', () => {
      if (document.querySelector('#campaign_default_passcode_custom')?.checked) {
        document.querySelector('.customized_passcode')?.classList.remove('hidden');
      } else {
        document.querySelector('.customized_passcode')?.classList.add('hidden');
        document.querySelector('#campaign_custom_default_passcode').value = '';
      }
    });
  });

  // this event listener fires when you click outside the modal
  // it hides the modal, and then removes itself as an event handler
  const clickOutsideModalHandler = (event) => {
    if (!wizardPanel.contains(event.target)) {
      createModalWrapper.classList.add('hidden');
      document.removeEventListener('click', clickOutsideModalHandler);
    }
  };

  createCampaignButton?.addEventListener('click', () => {
    createModalWrapper.classList.remove('hidden');
    setTimeout(() => {
      document.addEventListener('click', clickOutsideModalHandler);
    });
  });

  document.querySelector('.button__cancel')?.addEventListener('click', (e) => {
    e.preventDefault();
    createModalWrapper.classList.add('hidden');
    document.removeEventListener('click', clickOutsideModalHandler);
  });

  if (createModalWrapper?.classList.contains('show-create-modal')) {
    createCampaignButton?.click();
  }
};
