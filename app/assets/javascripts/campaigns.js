import React from 'react';
import { createRoot } from 'react-dom/client';
import './utils/editable';
import CampaignCourseSearch from './components/campaign/campaign_course_search.jsx';

document.addEventListener('DOMContentLoaded', () => {
  const createCampaignButton = document.querySelector(
    '.create-campaign-button',
  );
  const createModalWrapper = document.querySelector('.create-modal-wrapper');
  const wizardPanel = document.querySelector('.wizard__panel');

  document
    .querySelector('.campaign-delete')
    ?.addEventListener('submit', (e) => {
      const title = prompt(
        I18n.t('campaign.confirm_campaign_deletion', {
          title: e.target.dataset.title,
        }),
      );
      if (title !== e.target.dataset.title) {
        if (title !== null) {
          alert(I18n.t('campaign.confirm_campaign_deletion_failed', { title }));
        }
        e.preventDefault();
      }
    });

  const campaignDetailsElements = document.querySelectorAll('.campaign-details');
  let clickOutsideHandler = null;

  campaignDetailsElements.forEach((campaignDetails) => {
    campaignDetails.addEventListener('editable:edit', (e) => {
      const target = e.target;
      const popContainer = target.querySelector('.pop__container');
      const popButton = target.querySelector('.plus');

      if (popButton) {
        popButton.style.display = 'block';
        popButton.onclick = () => {
          const pop = popContainer?.querySelector('.pop');
          if (pop) {
            pop.classList.toggle('open');
          }

          if (clickOutsideHandler) {
            document.removeEventListener('click', clickOutsideHandler);
          }

          clickOutsideHandler = (clickEvent) => {
            if (popContainer && !popContainer.contains(clickEvent.target)) {
              const popElement = popContainer.querySelector('.pop');
              if (popElement) {
                popElement.classList.remove('open');
              }
            }
          };

          document.addEventListener('click', clickOutsideHandler);
        };
      }

      const saveButton = campaignDetails.querySelector('.rails_editable-save');
      if (saveButton) {
        saveButton.onclick = () => {
          const form = document.getElementById('edit_campaign_details');
          if (form) {
            form.dispatchEvent(new Event('submit', { bubbles: true }));
          }
        };
      }
    });

    campaignDetails.addEventListener('editable:read', (e) => {
      const target = e.target;
      const plusButton = target.querySelector('.plus');
      const popContainer = target.querySelector('.pop__container');

      if (plusButton) {
        plusButton.style.display = 'none';
      }
      if (popContainer) {
        popContainer.classList.remove('open');
      }
    });
  });

  document
    .querySelector('.remove-organizer-form')
    ?.addEventListener('submit', (e) => {
      if (
        !confirm(
          I18n.t('users.remove_confirmation', {
            username: e.target.dataset.username,
          }),
        )
      ) {
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
      if (
        document.querySelector('#campaign_default_passcode_custom')?.checked
      ) {
        document
          .querySelector('.customized_passcode')
          ?.classList.remove('hidden');
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

  // Course Title React Search Component
  const reactCampaignCourseSearch = document.getElementById('react_campaign_course_search');
  if (reactCampaignCourseSearch) {
    let initialCourses = [];
    let courseOptions = [];
    try {
      initialCourses = JSON.parse(reactCampaignCourseSearch.dataset.initialCourses || '[]');
      if (!Array.isArray(initialCourses)) initialCourses = [initialCourses];
    } catch (e) {
      initialCourses = [];
    }

    try {
      courseOptions = JSON.parse(reactCampaignCourseSearch.dataset.courseOptions || '[]');
      if (!Array.isArray(courseOptions)) courseOptions = [];
    } catch (e) {
      courseOptions = [];
    }

    // Map array of strings to correct format for AsyncSelect, filtering out nulls
    const initialOptions = initialCourses
      .filter(c => c !== null && c !== '')
      .map(c => ({ label: String(c), value: String(c) }));

    const availableOptions = courseOptions
      .filter(c => c !== null && c !== '')
      .map(c => ({ label: String(c), value: String(c) }));

    const courseStringPrefix = reactCampaignCourseSearch.dataset.courseStringPrefix || 'courses';

    const root = createRoot(reactCampaignCourseSearch);
    root.render(
      React.createElement(CampaignCourseSearch, {
        initialCourses: initialOptions,
        courseStringPrefix,
        courseOptions: availableOptions
      })
    );
  }

  // Advanced Search Toggle
  const toggleAdvancedSearchBtn = document.getElementById(
    'toggle_advanced_search',
  );
  const advancedSearchFields = document.getElementById(
    'advanced_search_fields',
  );

  if (toggleAdvancedSearchBtn && advancedSearchFields) {
    toggleAdvancedSearchBtn.addEventListener('click', () => {
      advancedSearchFields.classList.toggle('hidden');
      const icon = toggleAdvancedSearchBtn.querySelector('.icon');
      if (icon) {
        if (advancedSearchFields.classList.contains('hidden')) {
          icon.classList.remove('icon-arrow-up');
          icon.classList.add('icon-arrow-down');
        } else {
          icon.classList.remove('icon-arrow-down');
          icon.classList.add('icon-arrow-up');
        }
      }
    });
  }
});
