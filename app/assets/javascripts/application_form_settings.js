// The question group list on the application form settings page
// (course_application_forms/edit): drag-and-drop or Move up/Move down to
// reorder, Remove to take a group off, and a searchable picker to add one.
// Nothing is saved until the form's Save button; the list's hidden inputs
// carry the order.

const list = document.querySelector('[data-question-group-list]');
const template = document.querySelector('[data-question-group-row-template]');
const addSelect = document.querySelector('[data-question-group-add-select]');
const addButton = document.querySelector('[data-question-group-add]');

// Searchable when TomSelect (from the main bundle) is present; a plain select otherwise.
const picker = addSelect && typeof TomSelect !== 'undefined'
  ? new TomSelect(addSelect, { allowEmptyOption: true })
  : null;

const rowOf = element => element.closest('[data-question-group-id]');

const moveRow = (row, direction) => {
  if (direction === 'up' && row.previousElementSibling) {
    list.insertBefore(row, row.previousElementSibling);
  } else if (direction === 'down' && row.nextElementSibling) {
    list.insertBefore(row.nextElementSibling, row);
  }
};

// Puts a removed group back in the picker.
const offerGroup = (id, name) => {
  if (picker) {
    picker.addOption({ value: id, text: name });
    picker.refreshOptions(false);
  } else if (addSelect) {
    addSelect.add(new Option(name, id));
  }
};

const unofferGroup = (id) => {
  if (picker) {
    picker.removeOption(id);
    picker.clear();
  } else {
    addSelect.querySelector(`option[value="${id}"]`)?.remove();
    addSelect.value = '';
  }
};

const buildRow = (id, name) => {
  const row = template.content.firstElementChild.cloneNode(true);
  row.dataset.questionGroupId = id;
  row.querySelector('input[type="hidden"]').value = id;
  const nameSpan = row.querySelector('.course-application-form__group-name');
  nameSpan.textContent = name;
  nameSpan.id = `question_group_name_${id}`;
  row.querySelectorAll('[aria-describedby]').forEach((control) => {
    control.setAttribute('aria-describedby', nameSpan.id);
  });
  const edit = row.querySelector('a');
  edit.href = edit.getAttribute('href').replace('ID', id);
  return row;
};

const addGroup = () => {
  const id = addSelect.value;
  if (!id) return;
  const name = addSelect.querySelector(`option[value="${id}"]`).textContent;
  list.appendChild(buildRow(id, name));
  unofferGroup(id);
};

if (list) {
  list.addEventListener('click', (event) => {
    const button = event.target.closest('button');
    if (!button) return;
    const row = rowOf(button);
    if (button.dataset.questionGroupMove) {
      moveRow(row, button.dataset.questionGroupMove);
      button.focus();
    } else if ('questionGroupRemove' in button.dataset) {
      const name = row.querySelector('.course-application-form__group-name').textContent;
      offerGroup(row.dataset.questionGroupId, name);
      // Focus goes to the neighbouring row's Remove button, or the Add button.
      const neighbour = row.nextElementSibling || row.previousElementSibling;
      row.remove();
      (neighbour?.querySelector('[data-question-group-remove]') || addButton)?.focus();
    }
  });

  // Drag-and-drop: the dragged row follows the pointer through the list.
  let dragged = null;
  list.addEventListener('dragstart', (event) => {
    dragged = rowOf(event.target);
    if (!dragged) return;
    dragged.classList.add('course-application-form__group--dragging');
    event.dataTransfer.effectAllowed = 'move';
  });
  list.addEventListener('dragover', (event) => {
    if (!dragged) return;
    event.preventDefault();
    const target = rowOf(event.target);
    if (!target || target === dragged) return;
    const { top, height } = target.getBoundingClientRect();
    const after = event.clientY > top + height / 2;
    list.insertBefore(dragged, after ? target.nextElementSibling : target);
  });
  list.addEventListener('drop', event => event.preventDefault());
  list.addEventListener('dragend', () => {
    dragged?.classList.remove('course-application-form__group--dragging');
    dragged = null;
  });
}

addButton?.addEventListener('click', addGroup);
