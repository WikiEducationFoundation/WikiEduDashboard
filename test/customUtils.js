import './testHelper';
import { Simulate } from 'react-addons-test-utils';

export function click(el) {
  return new Promise((resolve) => {
    Simulate.click(el);
    return resolve(el);
  });
};
