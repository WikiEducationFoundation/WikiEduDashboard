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
