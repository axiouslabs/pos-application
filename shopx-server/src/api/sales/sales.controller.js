const asyncHandler = require("express-async-handler");
const service = require("./sales.service");

exports.createSale = asyncHandler(async (req, res) => {
  const data = req.body;

  // Automatically take salesperson from token
  data.salesperson_id = req.user.id;

  const sale = await service.createSale(data);

  res.status(201).json({
    message: "Sale created successfully",
    sale,
  });
});

exports.getSaleById = asyncHandler(async (req, res) => {
  const invoice = await service.getFullInvoice(req.params.id);
  res.json(invoice);
});

// exports.getAllSales = asyncHandler(async (req, res) => {
//   const limit = Number(req.query.limit || 20);
//   const sales = await service.getAllSales(limit);
//   res.json(sales);
// });

exports.getAllSales = asyncHandler(async (req, res) => {
  const { from, to, salesperson, status } = req.query;

  const sales = await service.getAllSales({
    from,
    to,
    salesperson,
    status,
  });

  res.json(sales);
});

// exports.getMySales = asyncHandler(async (req, res) => {
//   const sales = await service.getSalesBySalesperson(req.user.id);
//   res.json(sales);
// });

exports.getMySales = asyncHandler(async (req, res) => {
  const { from, to, status } = req.query;

  const sales = await service.getSalesBySalesperson(req.user.id, {
    from,
    to,
    status,
  });

  res.json(sales);
});
exports.voidSale = asyncHandler(async (req, res) => {
  const saleId = req.params.id;

  const result = await service.voidSale(saleId, req.user);

  res.json({
    message: "Sale voided successfully",
    result,
  });
});

exports.reviseSale = asyncHandler(async (req, res) => {
  const saleId = req.params.id;
  const updatedData = req.body;

  const result = await service.reviseSale(saleId, updatedData, req.user);

  res.json({
    message: "Sale revised successfully",
    result,
  });
});
