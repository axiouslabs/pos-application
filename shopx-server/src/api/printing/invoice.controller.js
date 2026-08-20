const asyncHandler = require("express-async-handler");
const service = require("./invoice.service");

const formatter = require("./reciept.formatter");
const db = require("../../config/db");

exports.getInvoicePDF = asyncHandler(async (req, res) => {
  const { saleId } = req.params;

  const filePath = await service.generateInvoicePDF(saleId);

  res.download(filePath, (err) => {
    if (err) console.log(err);
  });
});




exports.getReceiptData = async (req, res) => {
  const { saleId } = req.params;

  const sale = await db.query(
    `SELECT s.*, c.name AS customer_name, sp.name AS salesperson_name
     FROM sales s
     LEFT JOIN customers c ON c.id = s.customer_id
     LEFT JOIN salespersons sp ON sp.id = s.salesperson_id
     WHERE s.id = $1`, 
  [saleId]);

  if (sale.rows.length === 0) throw new Error("Sale not found");

  const items = await db.query(
    `SELECT si.quantity, si.unit_price, si.total_price, p.name
     FROM sale_items si
     JOIN products p ON p.id = si.product_id
     WHERE si.sale_id = $1`,
    [saleId]
  );

  const receipt = formatter.formatReceipt(sale.rows[0], items.rows);
  res.json(receipt);
};


