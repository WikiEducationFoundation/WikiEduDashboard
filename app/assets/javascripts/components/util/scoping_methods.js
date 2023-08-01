import { CATEGORIES, PAGEPILE, PETSCAN, TEMPLATES } from '../../constants/scoping_methods';

export const allScopingMethods = [
  CATEGORIES,
  PAGEPILE,
  PETSCAN,
  TEMPLATES,
];

export const getScopingMethodLabel = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan');
    case 'index':
      return I18n.t('courses_generic.creator.scoping_methods.configure');
    default:
      return '';
  }
};

export const getShortDescription = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories_short_desc');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates_short_desc');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile_short_desc');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan_short_desc');
    default:
      return '';
  }
};

export const getLongDescription = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories_desc');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates_desc');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile_desc');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan_desc');
    case 'index':
      return I18n.t('courses_generic.creator.scoping_methods.about');
    default:
      return '';
  }
};

export const getScopingMethods = (scopingMethods) => {
  const { selected } = scopingMethods;
  const result = {};

  // eslint-disable-next-line no-restricted-syntax
  for (const selectedItem of selected) {
    // only add the scoping method to the final object if it is selected
    result[selectedItem.toLowerCase()] = scopingMethods[selectedItem.toLowerCase()];
  }

  return result;
};

export const getAddCategoriesPayload = ({
  sourceType,
  scopingMethods
}) => {
  if (sourceType === 'category') {
    return {
      categories: {
        depth: scopingMethods.categories.depth,
        items: scopingMethods.categories.tracked
      }
    };
  } else if (sourceType === 'psid') {
    return {
      categories: {
        depth: 0,
        items: scopingMethods.petscan.psids
      }
    };
  } else if (sourceType === 'pileid') {
    return {
      categories: {
        depth: 0,
        items: scopingMethods.pagepile.ids
      }
    };
  }
  return {
    categories: {
      depth: 0,
      items: scopingMethods.templates.include
    }
  };
};
