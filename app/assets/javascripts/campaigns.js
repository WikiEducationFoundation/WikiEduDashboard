const List = require('list.js');
import jQuery from 'jquery';

jQuery(() => {
  jQuery('.campaign-delete').on('submit', (e) => {
    const title = prompt(I18n.t('campaign.confirm_campaign_deletion', { title: e.target.dataset.title }));
    if (title !== e.target.dataset.title) {
      if (title !== null) {
        alert(I18n.t('campaign.confirm_campaign_deletion_failed', { title }));
      }
      e.preventDefault();
    }
  });

  jQuery('.campaign-details').on('editable:edit', (e) => {
    const $popContainer = jQuery(e.target).find('.pop__container');
    const $popButton = jQuery(e.target).find('.plus');

    // add listener to show/hide the popup, removing any existing listener
    $popButton.show().off('click').on('click', () => {
      $popContainer.find('.pop').toggleClass('open');

      // allow popup to be closed when clicking outside the popup, again removing any existing listener
      jQuery(document).off('click.campaign-popover').on('click.campaign-popover', (cp) => {
        if (!jQuery(cp.target).parents('.pop__container').length) {
          $popContainer.find('.pop').removeClass('open');
        }
      });
    });

    // campaign details form submission
    jQuery('.campaign-details .rails_editable-save').on('click', () => {
      jQuery('#edit_campaign_details').trigger('submit');
    });
  });

  // close out the popup and hide pop button if existing edit mode
  jQuery('.campaign-details').on('editable:read', (e) => {
    jQuery(e.target).find('.plus').hide();
    jQuery(e.target).find('.pop__container').removeClass('open');
  });

  jQuery('.remove-organizer-form').on('submit', (e) => {
    if (!confirm(I18n.t('users.remove_confirmation', { username: e.target.dataset.username }))) {
      e.preventDefault();
    }
  });

  jQuery('#use_dates').on('change', (e) => {
    jQuery('.campaign-dates').toggleClass('hidden', !e.target.checked);
    if (!e.target.checked) {
      jQuery('#campaign_start').val('');
      jQuery('#campaign_end').val('');
    }
  });

  jQuery('.campaign_passcode').on('change', () => {
    jQuery('.customized_passcode').toggleClass('hidden', !jQuery('#campaign_default_passcode_custom')[0].checked);
    if (!jQuery('#campaign_default_passcode_custom')[0].checked) {
      jQuery('#campaign_default_passcode').val('');
    }
  });

  jQuery('.create-campaign-button').on('click', () => {
    jQuery('.create-modal-wrapper').removeClass('hidden');

    setTimeout(() => {
      jQuery(document).off('click.campaign-popover').on('click.campaign-popover', (cp) => {
        if (!jQuery(cp.target).parents('.wizard-wrapper').length) {
          jQuery('.create-modal-wrapper').addClass('hidden');
          jQuery(document).off('click.campaign-popover');
        }
      });
    });
  });

  jQuery('.button__cancel').on('click', (e) => {
    e.preventDefault();
    jQuery('.create-modal-wrapper').addClass('hidden');
    jQuery(document).off('click.campaign-popover');
  });

  if (jQuery('.create-modal-wrapper').hasClass('show-create-modal')) {
    jQuery('.create-campaign-button').trigger('click');
  }
  // Campaign sorting
  // only sort if there are tables to sort
  let campaignList;
  if (jQuery('.campaign-list table').length) {
    campaignList = new List('js-campaigns', {
      valueNames: [
        'title'
      ]
    });
  }

  return jQuery('select.sorts').on('change', function () {
    const list = (() => {
      switch (jQuery(this).attr('rel')) {
        case 'campaigns': return campaignList;
        default: break;
      }
})();
    if (list) {
      return list.sort(jQuery(this).val(), {
        order: jQuery(this).children('option:selected').attr('rel')
      });
    }
  });
});
