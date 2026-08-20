const repo = require("./customers.repository");
const { validateCustomer } = require("./customers.validator");

exports.createCustomer = async (data, user) => {
  const errors = validateCustomer(data);
  if (errors.length > 0) {
    throw new Error(errors.join(", "));
  }

  return await repo.createCustomer({
    ...data,
    salesperson_id: user.id,
  });
};


exports.getAllCustomers = async () => {
  return await repo.getAllCustomers();
};


exports.getMyCustomers = async (salespersonId) => {
  return await repo.getCustomersBySalesperson(salespersonId);
};


exports.getCustomerById = async (id) => {
  const customer = await repo.getCustomerById(id);
  if (!customer) throw new Error("Customer not found");

  return customer;
};

exports.updateCustomer = async (id, data) => {
  const updated = await repo.updateCustomer(id, data);
  if (!updated) throw new Error("Customer not found");

  return updated;
};

exports.deleteCustomer = async (id) => {
  const deleted = await repo.deleteCustomer(id);
  if (!deleted) throw new Error("Customer not found");

  return deleted;
};
