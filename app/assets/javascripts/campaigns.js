import $ from 'jquery';
import './utils/editable';
import 'jquery-ui/ui/widgets/autocomplete';


document.addEventListener('DOMContentLoaded', () => {
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
    createCampaignButton.click();
  }

  // Course Title Autocomplete
  const courseTitleInput = document.getElementById('course_title_search');
  const resultsContainer = document.getElementById('course_search_results');

  if (courseTitleInput && resultsContainer) {
    let timeout = null;

    courseTitleInput.addEventListener('input', (e) => {
      const query = e.target.value;
      if (timeout) clearTimeout(timeout);

      if (query.length < 3) {
        resultsContainer.innerHTML = '';
        resultsContainer.classList.add('hidden');
        return;
      }

      timeout = setTimeout(() => {
        fetch(`/courses/search.json?search=${encodeURIComponent(query)}`)
          .then(response => response.json())
          .then((data) => {
            resultsContainer.innerHTML = '';
            if (data.courses && data.courses.length > 0) {
              resultsContainer.classList.remove('hidden');
              data.courses.forEach((course) => {
                const div = document.createElement('div');
                div.textContent = course.title;
                div.style.padding = '8px';
                div.style.cursor = 'pointer';
                div.style.borderBottom = '1px solid #eee';
                div.addEventListener('mouseover', () => div.style.backgroundColor = '#f0f0f0');
                div.addEventListener('mouseout', () => div.style.backgroundColor = 'white');
                div.addEventListener('click', () => {
                  courseTitleInput.value = course.title;
                  resultsContainer.innerHTML = '';
                  resultsContainer.classList.add('hidden');
                });
                resultsContainer.appendChild(div);
              });
            } else {
              resultsContainer.classList.add('hidden');
            }
          })
          .catch(() => {
            resultsContainer.classList.add('hidden');
          });
      }, 300);
    });

    // Hide results when clicking outside
    document.addEventListener('click', (e) => {
      if (e.target !== courseTitleInput && e.target !== resultsContainer) {
        resultsContainer.classList.add('hidden');
      }
    });
  }

  // Advanced Search Toggle
  const toggleAdvancedSearchBtn = document.getElementById('toggle_advanced_search');
  const advancedSearchFields = document.getElementById('advanced_search_fields');

  if (toggleAdvancedSearchBtn && advancedSearchFields) {
    toggleAdvancedSearchBtn.addEventListener('click', () => {
      advancedSearchFields.classList.toggle('hidden');
      const icon = toggleAdvancedSearchBtn.querySelector('.icon');
      if (advancedSearchFields.classList.contains('hidden')) {
        icon.classList.remove('icon-arrow-up');
        icon.classList.add('icon-arrow-down');
      } else {
        icon.classList.remove('icon-arrow-down');
        icon.classList.add('icon-arrow-up');
      }
    });
  }
});
