exports.validateCustomer = (data) => {
  const errors = [];

  if (!data.name) {
    errors.push("Customer name is required");
  }

  // Phone → optional, validate only if present
  if (data.phone && data.phone.length < 8) {
    errors.push("Invalid phone number");
  }

  // TIN → optional, validate only if present
  if (data.tin && data.tin.length < 5) {
    errors.push("Invalid TIN");
  }

  return errors;
};
