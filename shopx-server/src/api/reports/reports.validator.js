// optional: you can add date string validation here
exports.validateDate = (value) => {
  if (!value) return true;
  // simple YYYY-MM-DD check (loose)
  return /^\d{4}-\d{2}-\d{2}$/.test(value);
};
