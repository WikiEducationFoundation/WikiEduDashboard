// This is fast and works for
// most of the cases.
const shallowCompare = (a, b) =>
  JSON.stringify(a) === JSON.stringify(b);

export default class ArrayUtils {
  static hasObject(arr, obj) {
    return arr.some(o => shallowCompare(o, obj));
  }
  static removeObject(arr, obj) {
    return arr.filter(o => !shallowCompare(o, obj));
  }
}
