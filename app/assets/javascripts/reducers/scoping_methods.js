import { RESET_SCOPING_METHODS, TOGGLE_SCOPING_METHOD, UPDATE_CATEGORIES, UPDATE_CATEGORY_DEPTH, UPDATE_PAGEPILE_IDS, UPDATE_PETSCAN_IDS, UPDATE_TEMPLATES } from '../constants/scoping_methods';

const initialState = {
  selected: [],
  categories: {
    depth: 0,
    tracked: [],
  },
  templates: {
    include: [],
  },
  petscan: {
    psids: [],
  },
  pagepile: {
    ids: [],
  },
  descriptionHidden: false,
};

export default function course(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_SCOPING_METHOD: {
      if (state.selected.includes(action.method)) {
        return {
          ...state,
          selected: state.selected.filter(method => method !== action.method).sort(),
        };
      }
      return {
        ...state,
        selected: [...state.selected, action.method].sort(),
      };
    }
    case UPDATE_CATEGORY_DEPTH: {
      return {
        ...state,
        categories: {
          ...state.categories,
          depth: action.depth
        }
      };
    }
    case UPDATE_CATEGORIES: {
      return {
        ...state,
        categories: {
          ...state.categories,
          tracked: action.categories
        }
      };
    }
    case UPDATE_TEMPLATES: {
      return {
        ...state,
        templates: {
          ...state.templates,
          include: action.templates
        }
      };
    }
    case UPDATE_PETSCAN_IDS: {
      return {
        ...state,
        petscan: {
          ...state.petscan,
          psids: action.psids
        }
      };
    }

    case UPDATE_PAGEPILE_IDS: {
      return {
        ...state,
        pagepile: {
          ...state.pagepile,
          ids: action.ids
        }
      };
    }

    case RESET_SCOPING_METHODS: {
      return initialState;
    }
    default:
      return state;
  }
}
