/**
 * Editable - a tiny vanilla JS plugin to turn blocks of text into inputs
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

document.addEventListener('DOMContentLoaded', () => {
  const readMode = (parent) => {
    parent.dispatchEvent(new CustomEvent('editable:read', { bubbles: true }));
    parent.classList.remove('rails_editable-editing');
    const cancelBtn = parent.querySelector('.rails_editable-cancel');
    const saveBtn = parent.querySelector('.rails_editable-save');
    const editBtn = parent.querySelector('.rails_editable-edit');
    const contents = parent.querySelectorAll('.rails_editable-content');
    const inputs = parent.querySelectorAll('.rails_editable-input');

    if (cancelBtn) cancelBtn.remove();
    if (saveBtn) saveBtn.remove();
    if (editBtn) editBtn.style.display = '';
    contents.forEach(el => el.style.display = '');
    inputs.forEach(el => el.style.display = 'none');
  };

  const editMode = (e) => {
    e.preventDefault();
    const button = e.target;
    const parent = button.closest('.rails_editable');
    if (!parent) return;

    parent.classList.add('rails_editable-editing');
    button.style.display = 'none';

    const disclaimer = parent.querySelector('#disclaimer');
    if (disclaimer) disclaimer.style.display = 'unset';

    const userImage = parent.querySelector('#profile_left #user_image');
    if (userImage) userImage.style.height = '150px';

    const buttonContainer = button.parentElement;
    const cancelBtn = document.createElement('button');
    cancelBtn.className = 'rails_editable rails_editable-cancel button';
    cancelBtn.textContent = I18n.t('editable.cancel');

    const saveBtn = document.createElement('button');
    saveBtn.className = 'rails_editable rails_editable-save button dark';
    saveBtn.textContent = I18n.t('editable.save');

    buttonContainer.appendChild(cancelBtn);
    buttonContainer.appendChild(saveBtn);

    const fields = parent.querySelectorAll('.rails_editable-field');
    fields.forEach((field) => {
      const content = field.querySelector('.rails_editable-content');
      const input = field.querySelector('.rails_editable-input');
      if (!content || !input) return;

      const text = content.textContent.trim();
      content.style.display = 'none';
      input.value = text;
      if (input.type === 'textarea') {
        input.style.height = '400px';
      }
      input.style.display = '';
    });

    cancelBtn.addEventListener('click', () => {
      const disclaimerEl = parent.querySelector('#disclaimer');
      if (disclaimerEl) disclaimerEl.style.display = 'none';
      const userImageEl = parent.querySelector('#profile_left #user_image');
      if (userImageEl) userImageEl.style.height = 'unset';
      parent.dispatchEvent(new CustomEvent('editable:cancel', { bubbles: true }));
      readMode.call(this, parent);
    });

    saveBtn.addEventListener('click', () => {
      parent.dispatchEvent(new CustomEvent('editable:save', { bubbles: true }));
    });

    parent.dispatchEvent(new CustomEvent('editable:edit', { bubbles: true }));
  };

  document.querySelectorAll('.rails_editable-edit').forEach((button) => {
    button.addEventListener('click', editMode);
  });

  // if rails_editable-editing is present, enable edit mode on that element
  document.querySelectorAll('.rails_editable-editing').forEach((field) => {
    const editBtn = field.querySelector('.rails_editable-edit');
    if (editBtn) {
      editBtn.click();
    }
  });
});
