$(() => {
  const readMode = $parent => {
    $parent.find('.editable-cancel, .editable-save').remove();
    $parent.find('.editable-edit').show();
    $parent.find('.editable-content').show();
    $parent.find('.editable-input').hide();
  };

  const editMode = e => {
    e.preventDefault();
    const $parent = $(e.target).parents('.editable');
    $(e.target).hide();
    $(e.target).parent().append(`
      <button class='editable editable-cancel button'>${I18n.t('editable.cancel')}</button>
      <button class='editable editable-save button dark'>${I18n.t('editable.save')}</button>
    `);

    $.each($parent.find('.editable-field'), (_i, field) => {
      const $content = $(field).find('.editable-content');
      const $input = $(field).find('.editable-input');
      $content.hide();
      $input.val($content.text().trim());
      $input.show();
    });

    $('.editable-cancel').on('click', readMode.bind(this, $parent));
  };

  $('.editable-edit').on('click', editMode);
});
