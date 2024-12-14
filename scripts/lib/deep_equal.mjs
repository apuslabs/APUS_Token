export function deepEqual(obj1, obj2) {
  const stringifyWithSorting = (obj) => {
    if (Array.isArray(obj)) {
      return JSON.stringify(obj.map((item) => stringifyWithSorting(item)).sort());
    } else if (obj && typeof obj === 'object') {
      return JSON.stringify(
        Object.keys(obj)
          .sort()
          .reduce((acc, key) => {
            acc[key] = stringifyWithSorting(obj[key]);
            return acc;
          }, {})
      );
    } else {
      return JSON.stringify(obj);
    }
  };

  return stringifyWithSorting(obj1) === stringifyWithSorting(obj2);
}
