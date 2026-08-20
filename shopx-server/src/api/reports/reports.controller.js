const service = require("./reports.service");

exports.summary = async (req, res) => {
  const { start, end } = req.query;
  const data = await service.getSummary(start, end);
  res.json(data);
};

exports.salesman = async (req, res) => {
  const { start, end } = req.query;
  const data = await service.getSalesmanPerformance(start, end);
  res.json(data);
};

exports.products = async (req, res) => {
  const { start, end } = req.query;
  const data = await service.getProductSales(start, end);
  res.json(data);
};

exports.customers = async (req, res) => {
  const { start, end } = req.query;
  const data = await service.getCustomerPerformance(start, end);
  res.json(data);
};

exports.productPerformance = async (req, res) => {
  const { start, end, salespersonId } = req.query;

  const data = await service.getProductPerformance(
    start,
    end,
    salespersonId || null
  );

  res.json(data);
};


exports.productPerformanceForUser = async (req, res) => {
  const { start, end } = req.query;

  // 🔒 FORCE salesperson from token
  const salespersonId = req.user.id;

  const data = await service.getProductPerformance(
    start,
    end,
    salespersonId
  );

  res.json(data);
};
