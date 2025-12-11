/**
 * Editable - a tiny jQuery plugin to turn blocks of text into inputs
 *
 * To use:
 * - Build a normal Rails form, adding the class '.rails_editable' to the <form> tag.
 * - Add the blocks of text you want to be editable, each having an associated input field as a sibling.
 * - Each pair of a text block and input should be wrapped in a element with the class '.rails_editable-field'.
 * - Blocks of text should have the class .rails_editable-content
 * - Inputs should have the class .rails_editable-input (they are hidden via CSS, otherwise use the inline style 'display:none').
 * - Add an edit button somewhere within the form with the class '.rails_editable-edit'.
 *
 * - When the Edit button is clicked:
 *   - The class '.rails_editable-editing' is added to '.rails_editable'
 *   - The script will prevent the form from being submitted, so you can use a <button> element.
 *   - The inputs are supplied with the content of the associated text blocks, and the text blocks are hidden.
 *   - Textareas will have the same size as the corresponding text block
 *   - Cancel and Save buttons are appended to the parent. Construct your markup accordingly.
 *   - Cancel will revert back to showing the text blocks and hide the inputs.
 *   - Save will submit the form as a normal submit button would.
 *
 * - Events, fired on the parent .rails_editable
 *   - editable:edit - when the edit button is clicked, after DOM is updated
 *   - editable:cancel - when the cancel button is clicked
 *   - editable:save - when the save button is clicked
 *   - editable:read - when reverting back to the initial read-only view, either via Cancel or Save buttons
 *
 * To make an .rails_editable area be in "edit mode" when the script is loaded, append .rails_editable-editing
 */
$(() => {
  const readMode = ($parent) => {
    $parent.trigger('editable:read');
    $parent.removeClass('rails_editable-editing');
    $parent.find('.rails_editable-cancel, .rails_editable-save').remove();
    $parent.find('.rails_editable-edit').show();
    $parent.find('.rails_editable-content').show();
    $parent.find('.rails_editable-input').hide();
  };

  const editMode = (e) => {
    e.preventDefault();
    const $parent = $(e.target).parents('.rails_editable');
    const isInstructor = $parent.attr('data-is-instructor') === 'true';
    $parent.addClass('rails_editable-editing');
    $(e.target).hide();
    $parent.find('#disclaimer').css({ display: 'unset' });
    $parent.find('#profile_left #user_image').css({ height: '150px' });
    $(e.target).parent().append(`
      <button class='rails_editable rails_editable-cancel button'>${I18n.t('editable.cancel')}</button>
      <button class='rails_editable rails_editable-save button dark'>${I18n.t('editable.save')}</button>
    `);

    $.each($parent.find('.rails_editable-field'), (_i, field) => {
      const $content = $(field).find('.rails_editable-content');
      const $input = $(field).find('.rails_editable-input');
      const text = $content.text().trim();
      $content.hide();
      $input.val(text);
      if ($input.prop('type') === 'textarea') {
        $input.height('400px');
      }
      $input.show();
    });

    const $emailInput = $parent.find('#user_email .rails_editable-input');
    const $saveButton = $parent.find('.rails_editable-save');
    const $emailSection = $parent.find('#user_email');
    const errorMessageClass = 'email-error-message';

    const validateEmailField = () => {
      const email = $emailInput.val().trim();
      const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

      // Remove any old error
      $emailSection.find(`.${errorMessageClass}`).remove();

      let hasError = false;
      let errorMsg = '';

      if (isInstructor) {
        if (email === '') {
          hasError = true;
          errorMsg = I18n.t('users.email_required_instructor');
        } else if (!emailRegex.test(email)) {
          hasError = true;
          errorMsg = I18n.t('users.email_invalid');
        }
      }

      if (hasError) {
        $saveButton.prop('disabled', true).addClass('disabled');
        $emailSection.append(`
      <div style="margin-left: 20px;">
        <span class="${errorMessageClass}" style="color: red; font-size: 12px;">
          ${errorMsg}
        </span>
      </div>
    `);
      } else {
        errorMsg = '';
        $saveButton.prop('disabled', false).removeClass('disabled');
      }
    };

    // Run validation immediately and whenever the input changes
    $emailInput.on('input', validateEmailField);
    validateEmailField();

    $parent.find('.rails_editable-cancel').on('click', () => {
      $parent.find('#disclaimer').css({ display: 'none' });
      $parent.find('#profile_left #user_image').css({ height: 'unset' });
      $emailInput.off('input', validateEmailField);
      $parent.find('.email-error-message').remove();
      $parent.find('.rails_editable-save').prop('disabled', false).removeClass('disabled');

      readMode.call(this, $parent);
    });

    $parent.find('.rails_editable-save').on('click', () => {
      if (!$saveButton.is(':disabled')) {
        $parent.trigger('editable:save');
      }
    });

    $parent.trigger('editable:edit');
  };

  $('.rails_editable-edit').on('click', editMode);

  // if rails_editable-editing is present, enable edit mode on that element
  $.each($('.rails_editable-editing'), (_i, field) => {
    $(field).find('.rails_editable-edit').trigger('click');
  });
});
