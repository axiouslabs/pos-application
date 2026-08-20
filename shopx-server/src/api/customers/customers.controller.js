const service = require("./customers.service");
const asyncHandler = require("express-async-handler");


exports.createCustomer = asyncHandler(async (req, res) => {
  const customer = await service.createCustomer(req.body, req.user);
  res.status(201).json({ message: "Customer created", customer });
});


exports.getAllCustomers = asyncHandler(async (req, res) => {
  const customers = await service.getAllCustomers();
  res.json(customers);
});

exports.getMyCustomers = asyncHandler(async (req, res) => {
  const customers = await service.getMyCustomers(req.user.id);
  res.json(customers);
});


exports.getCustomerById = asyncHandler(async (req, res) => {
  const customer = await service.getCustomerById(req.params.id);
  res.json(customer);
});

exports.updateCustomer = asyncHandler(async (req, res) => {
  const customer = await service.updateCustomer(req.params.id, req.body);
  res.json({ message: "Customer updated", customer });
});

exports.deleteCustomer = asyncHandler(async (req, res) => {
  const result = await service.deleteCustomer(req.params.id);
  res.json({ message: "Customer deleted" });
});
