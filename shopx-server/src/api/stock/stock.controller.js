const asyncHandler = require("express-async-handler");
const stockService = require("./stock.service");

exports.adjust = asyncHandler(async (req, res) => {
  const { product_id, quantity_change, reason } = req.body;
  if (!product_id || typeof quantity_change !== "number") {
    res.status(400);
    throw new Error("product_id and numeric quantity_change are required");
  }
  const updated = await stockService.adjustStock(product_id, quantity_change, reason || "manual");
  res.json({ message: "Stock adjusted", stock: updated });
});

exports.getStock = asyncHandler(async (req, res) => {
  const productId = req.params.id;
  const stock = await stockService.getStock(productId);
  res.json(stock || { product_id: productId, quantity: 0 });
});

exports.getAll = asyncHandler(async (req, res) => {
  const rows = await stockService.getAllStock();
  res.json(rows);
});

exports.getMovements = asyncHandler(async (req, res) => {
  const productId = req.params.id;
  const rows = await stockService.getStockMovements(productId);
  res.json(rows);
});
