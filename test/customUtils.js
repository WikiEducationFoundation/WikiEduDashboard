import { Simulate } from 'react-dom/test-utils';
import './testHelper';

export function click(el) {
  return new Promise((resolve) => {
    Simulate.click(el);
    return resolve(el);
  });
}
