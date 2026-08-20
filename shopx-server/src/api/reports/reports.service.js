const repo = require("./reports.repository");

exports.getSummary = async (start, end) => {
  return await repo.getSummary(start, end);
};

exports.getSalesmanPerformance = async (start, end) => {
  return await repo.getSalesmanPerformance(start, end);
};

exports.getProductSales = async (start, end) => {
  return await repo.getProductSales(start, end);
};

exports.getCustomerPerformance = async (start, end) => {
  return await repo.getCustomerPerformance(start, end);
};

exports.getProductPerformance = async (start, end, salespersonId) => {
  return await repo.getProductPerformance(start, end, salespersonId);
};
