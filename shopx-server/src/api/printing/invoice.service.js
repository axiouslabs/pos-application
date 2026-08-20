const db = require("../../config/db");
const PDFDocument = require("pdfkit");
const fs = require("fs");
const path = require("path");

exports.generateInvoicePDF = async (saleId) => {
  // Fetch sale
  const sale = await db.query(
    `SELECT s.*, c.name AS customer_name, sp.name AS salesperson_name
     FROM sales s
     LEFT JOIN customers c ON c.id = s.customer_id
     LEFT JOIN salespersons sp ON sp.id = s.salesperson_id
     WHERE s.id = $1`, [saleId]
  );

  if (sale.rows.length === 0) {
    throw new Error("Sale not found");
  }

  const saleData = sale.rows[0];

  // Fetch items
  const items = await db.query(
    `SELECT si.quantity, si.unit_price, si.total_price, p.name
     FROM sale_items si
     JOIN products p ON p.id = si.product_id
     WHERE si.sale_id = $1`,
    [saleId]
  );

  // Create PDF
  const doc = new PDFDocument({ margin: 40 });
  const filePath = path.join(__dirname, `invoice_${saleId}.pdf`);
// create & store stream
const stream = fs.createWriteStream(filePath);
// pipe pdf output into stream
doc.pipe(stream);


  // Header
  doc.fontSize(20).text("INVOICE", { align: "center" });
  doc.moveDown();

  // Customer + Sale details
  doc.fontSize(12).text(`Invoice ID: ${saleId}`);
  doc.text(`Date: ${new Date(saleData.created_at).toDateString()}`);
  doc.text(`Customer: ${saleData.customer_name}`);
  doc.text(`Salesperson: ${saleData.salesperson_name}`);
  doc.moveDown();

  // Table header
  doc.fontSize(14).text("Items:", { underline: true });
  doc.moveDown(0.5);

  // Table rows
  items.rows.forEach((item) => {
    doc.fontSize(12).text(
      `${item.name} - Qty: ${item.quantity} × ₹${item.unit_price} = ₹${item.total_price}`
    );
  });

  doc.moveDown();
  doc.fontSize(16).text(`Total: ₹${saleData.total_amount}`, { align: "right" });
doc.end();

// Wait for PDF to finish writing
return new Promise((resolve, reject) => {
  stream.on("finish", () => resolve(filePath));
  stream.on("error", reject);
});

};
