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
      <button class='rails_editable rails_editable-cancel button'>${I18n.t('rails_editable.cancel')}</button>
      <button class='rails_editable rails_editable-save button dark'>${I18n.t('rails_editable.save')}</button>
    `);

    $.each($parent.find('.rails_editable-field'), (_i, field) => {
      const $content = $(field).find('.rails_editable-content');
      const $input = $(field).find('.rails_editable-input');
      $content.hide();
      $input.val($content.text().trim());
      $input.show();
    });

    $('.rails_editable-cancel').on('click', readMode.bind(this, $parent));
  };

  $('.rails_editable-edit').on('click', editMode);
});
