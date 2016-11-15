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
 *   - The script will prevent the form from being submitted, so you can use a <button> element.
 *   - The inputs are supplied with the content of the associated text blocks, and the text blocks are hidden.
 *   - Textareas will have the same size as the corresponding text block
 *   - Cancel and Save buttons are appended to the parent. Construct your markup accordingly.
 *   - Cancel will revert back to showing the text blocks and hide the inputs.
 *   - Save will submit the form as a normal submit button would.
 */
$(() => {
  const readMode = $parent => {
    $parent.find('.rails_editable-cancel, .rails_editable-save').remove();
    $parent.find('.rails_editable-edit').show();
    $parent.find('.rails_editable-content').show();
    $parent.find('.rails_editable-input').hide();
  };

  const editMode = e => {
    e.preventDefault();
    const $parent = $(e.target).parents('.rails_editable');
    $(e.target).hide();
    $(e.target).parent().append(`
      <button class='rails_editable rails_editable-cancel button'>${I18n.t('editable.cancel')}</button>
      <button class='rails_editable rails_editable-save button dark'>${I18n.t('editable.save')}</button>
    `);

    $.each($parent.find('.rails_editable-field'), (_i, field) => {
      const $content = $(field).find('.rails_editable-content');
      const $input = $(field).find('.rails_editable-input');
      $content.hide();
      $input.val($content.text().trim());
      if ($input.prop('type') === 'textarea') {
        $input.height($content.innerHeight());
      }
      $input.show();
    });

    $('.rails_editable-cancel').on('click', readMode.bind(this, $parent));
  };

  $('.rails_editable-edit').on('click', editMode);
});
