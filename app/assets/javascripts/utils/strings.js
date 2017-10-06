export function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export function trunc(str, truncation = 15) {
  if (str.length > truncation + 3) {
    return `${str.substring(0, truncation)}…`;
  }
  return str.valueOf();
}
