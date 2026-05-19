window.DISABLE_ARTICLES_LISTJS = true;

document.addEventListener('DOMContentLoaded', () => {
  const toggleAdvancedSearchBtn = document.getElementById('toggle_advanced_search');
  const advancedSearchFields = document.getElementById('advanced_search_fields');

  if (toggleAdvancedSearchBtn && advancedSearchFields) {
    toggleAdvancedSearchBtn.addEventListener('click', () => {
      advancedSearchFields.classList.toggle('hidden');
    });
  }

  if (typeof TomSelect !== 'undefined') {
    new TomSelect('#school_select', {
      plugins: ['remove_button'],
      placeholder: `${I18n.t('assignments.select')} ${I18n.t('courses.school')}...`,
      allowEmptyOption: true
    });
  }

  const headers = document.querySelectorAll('#campaign-articles table th.sortable');

  headers.forEach((th) => {
    th.style.cursor = 'pointer';

    th.onclick = (e) => {
      e.preventDefault();
      e.stopImmediatePropagation();

      const backendColumn = th.getAttribute('data-backend-column');
      const defaultOrder = th.getAttribute('data-default-order') || 'asc';

      const urlParams = new URLSearchParams(window.location.search);
      const currentSort = urlParams.get('sort');
      const currentDirection = urlParams.get('direction');

      let newDirection = defaultOrder;
      if (currentSort === backendColumn) {
        newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
      }

      urlParams.set('sort', backendColumn);
      urlParams.set('direction', newDirection);
      urlParams.delete('page');

      window.location.href = `${window.location.pathname}?${urlParams.toString()}`;
    };
  });
});
