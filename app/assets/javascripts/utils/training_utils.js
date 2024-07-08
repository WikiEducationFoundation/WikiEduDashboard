// utils/domUtils.js
export const extractCategoriesFromHtml = () => {
  const categoriesFromHtml = Array.from(document.querySelectorAll('.training__categories > li')).map((li) => {
    const nameElement = li.querySelector('.training__category__header h1');
    const descriptionElement = li.querySelector('.training__category__header p');

    const name = nameElement ? nameElement.innerText.trim() : '';
    const description = descriptionElement ? descriptionElement.innerText.trim() : '';
    return { name, description };
  });
  return categoriesFromHtml;
};
