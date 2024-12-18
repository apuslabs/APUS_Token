export function containsSubset(bigObj, smallObj) {
  return Object.keys(smallObj).every(key => {
    return bigObj.hasOwnProperty(key) && bigObj[key] === smallObj[key];
  });
}