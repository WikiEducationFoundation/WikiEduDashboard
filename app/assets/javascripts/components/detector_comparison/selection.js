import { useSearchParams } from 'react-router-dom';
import { DEFAULT_SELECTION } from './descriptions';

// What the table shows is kept in the page address: one parameter per selection key, values
// separated by |, 'all' for everything, and 'group' for how rows are grouped.
const SEPARATOR = '|';
export const ALL = 'all';
export const SELECTION_KEYS = ['models', 'strategies', 'detectors', 'topics'];

const encode = value => (Array.isArray(value) ? value.join(SEPARATOR) : value);

const paramValue = (selection, key) => encode(selection[key] ?? DEFAULT_SELECTION[key]);

// The address parameters for a selection, such as a curated view's.
export const selectionParams = (selection) => {
  const params = new URLSearchParams();
  SELECTION_KEYS.forEach(key => params.set(key, paramValue(selection, key)));
  params.set('group', selection.group || 'model');
  return params;
};

// Whether the address currently shows exactly this selection.
export const showsSelection = (params, selection) => SELECTION_KEYS.every(key => (params.get(key) ?? encode(DEFAULT_SELECTION[key])) === paramValue(selection, key))
  && (params.get('group') || 'model') === (selection.group || 'model');

export const useSelection = (options) => {
  const [params, setParams] = useSearchParams();
  const read = (key) => {
    const raw = params.get(key) ?? encode(DEFAULT_SELECTION[key]);
    return raw === ALL ? options[key] : raw.split(SEPARATOR).filter(Boolean);
  };
  const selection = Object.fromEntries(SELECTION_KEYS.map(key => [key, read(key)]));
  selection.groupBy = params.get('group') || 'model';
  const write = (key, value) => {
    const next = new URLSearchParams(params);
    next.set(key, value);
    setParams(next, { replace: true });
  };
  const update = (key, values) => write(key, values.length === options[key].length ? ALL : values.join(SEPARATOR));
  const toggle = (key, value) => {
    const current = selection[key];
    update(key, current.includes(value) ? current.filter(item => item !== value) : options[key].filter(item => item === value || current.includes(item)));
  };
  return { selection, toggle, update, setGroupBy: value => write('group', value) };
};
