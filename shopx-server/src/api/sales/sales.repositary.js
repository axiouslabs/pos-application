const db = require("../../config/db");

// CREATE SALE

exports.createSale = async (
  client,
  {
    salesperson_id,
    customer_id,
    subtotal_amount,
    discount_amount,
    vat_percentage,
    vat_amount,
    total_amount,
    payment_method,
    payment_status,
  },
) => {
  const result = await client.query(
    `INSERT INTO sales 
     (
       salesperson_id,
       customer_id,
       subtotal_amount,
       discount_amount,
       vat_percentage,
       vat_amount,
       total_amount,
       payment_method,
       payment_status
     )
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
     RETURNING *`,
    [
      salesperson_id,
      customer_id,
      subtotal_amount,
      discount_amount,
      vat_percentage,
      vat_amount,
      total_amount,
      payment_method,
      payment_status,
    ],
  );

  return result.rows[0];
};

// INSERT SALE ITEM
exports.addSaleItem = async (client, sale_id, item) => {
  const discount = item.discount || 0;

  const total_price = item.quantity * (item.unit_price - discount);

  return await client.query(
    `INSERT INTO sale_items 
     (sale_id, product_id, quantity, fulfilled_quantity, unit_price, discount, total_price)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      sale_id,
      item.product_id,
      item.quantity,
      0, // 👈 fulfilled_quantity ALWAYS starts at 0
      item.unit_price,
      discount,
      total_price,
    ],
  );
};

exports.updateSaleStatus = async (client, saleId, status) => {
  await client.query(`UPDATE sales SET sale_status = $1 WHERE id = $2`, [
    status,
    saleId,
  ]);
};

// FULL INVOICE JOIN
exports.getFullInvoice = async (id) => {
  const sale = await db.query(
    `
      SELECT s.*, 
             u.username AS salesperson_name,
             c.name AS customer_name, 
             c.phone AS customer_phone,
             c.tin AS customer_tin   -- ✅ ADD THIS
      FROM sales s
      LEFT JOIN users u ON u.id = s.salesperson_id
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.id = $1
    `,
    [id],
  );
  const items = await db.query(
    `
    SELECT 
      si.id,
      si.sale_id,
      si.product_id,
      si.product_name,
      si.product_name_ar,
      si.quantity,
      si.fulfilled_quantity,
      si.unit_price,
      si.discount,
      si.total_price
    FROM sale_items si
    WHERE si.sale_id = $1
  `,
    [id],
  );

  const payments = await db.query(
    `SELECT * FROM payments WHERE sale_id = $1 ORDER BY created_at ASC`,
    [id],
  );

  return {
    sale: sale.rows[0],
    items: items.rows,
    payments: payments.rows,
  };
};

exports.getSaleById = async (client, id) => {
  const r = await client.query(`SELECT * FROM sales WHERE id = $1`, [id]);
  return r.rows[0];
};

exports.getSaleItems = async (client, saleId) => {
  const r = await client.query(`SELECT * FROM sale_items WHERE sale_id = $1`, [
    saleId,
  ]);
  return r.rows;
};

// BASIC LIST

// exports.getAllSales = async (limit = 20) => {
//   const r = await db.query(
//     `
//     SELECT
//       s.id,
//       s.customer_id,
//       s.subtotal_amount,
//       s.discount_amount,
//       s.vat_amount,
//       s.vat_percentage,
//       s.total_amount,
//       s.payment_status,
//       s.sale_status,        -- ✅ IMPORTANT
//       s.sale_date,
//       u.username AS salesperson_name,
//       c.name AS customer_name,
//       c.phone AS customer_phone
//     FROM sales s
//     LEFT JOIN users u ON u.id = s.salesperson_id
//     LEFT JOIN customers c ON c.id = s.customer_id
//     ORDER BY s.sale_date DESC
//     LIMIT $1
//     `,
//     [limit]
//   );

//   return r.rows;
// };

exports.getAllSales = async ({ from, to, salesperson, status }) => {
  let query = `
    SELECT
      s.id,
      s.customer_id,
      s.subtotal_amount,
      s.discount_amount,
      s.vat_amount,
      s.vat_percentage,
      s.total_amount,
      s.payment_status,
      s.sale_status,
      s.sale_date,
      u.username AS salesperson_name,
      c.name AS customer_name,
      c.phone AS customer_phone
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    LEFT JOIN customers c ON c.id = s.customer_id
    WHERE 1=1
  `;

  const values = [];
  let index = 1;

  if (from && to) {
    query += ` AND s.sale_date >= $${index} AND s.sale_date < $${index + 1}::date + INTERVAL '1 day'`;
    values.push(from, to);
    index += 2;
  }

  if (salesperson) {
    query += ` AND u.username = $${index}`;
    values.push(salesperson);
    index++;
  }

  if (status) {
    if (status === "CANCELLED") {
      query += ` AND s.sale_status = 'voided'`;
    } else {
      query += ` AND s.payment_status = $${index}`;
      values.push(status.toLowerCase());
      index++;
    }
  }

  query += ` ORDER BY s.sale_date DESC`;

  // Default limit only if NO filter is applied
  if (!from && !to && !salesperson && !status) {
    query += ` LIMIT 20`;
  }

  const r = await db.query(query, values);
  return r.rows;
};

// exports.getSalesBySalesperson = async (salespersonId) => {
//   const r = await db.query(
//     `
//     SELECT
//       s.id,
//       s.customer_id,
//       s.subtotal_amount,
//       s.discount_amount,
//       s.vat_amount,
//       s.vat_percentage,
//       s.total_amount,
//       s.payment_status,
//       s.sale_status,          -- ✅ CRITICAL: tells frontend if cancelled
//       s.sale_date,
//       u.username AS salesperson_name,
//       c.name AS customer_name,
//       c.phone AS customer_phone
//     FROM sales s
//     LEFT JOIN users u ON u.id = s.salesperson_id
//     LEFT JOIN customers c ON c.id = s.customer_id
//     WHERE s.salesperson_id = $1
//     ORDER BY s.sale_date DESC
//     `,
//     [salespersonId]
//   );

//   return r.rows;
// };

exports.getSalesBySalesperson = async (salespersonId, { from, to, status }) => {
  let query = `
    SELECT
      s.id,
      s.customer_id,
      s.subtotal_amount,
      s.discount_amount,
      s.vat_amount,
      s.vat_percentage,
      s.total_amount,
      s.payment_status,
      s.sale_status,
      s.sale_date,
      u.username AS salesperson_name,
      c.name AS customer_name,
      c.phone AS customer_phone
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    LEFT JOIN customers c ON c.id = s.customer_id
    WHERE s.salesperson_id = $1
  `;

  const values = [salespersonId];
  let index = 2;

  // ✅ DEFAULT → TODAY ONLY
  if (!from && !to) {
    query += ` AND s.sale_date >= CURRENT_DATE 
               AND s.sale_date < CURRENT_DATE + INTERVAL '1 day'`;
  }

  // ✅ DATE FILTER
  if (from && to) {
    query += ` AND s.sale_date >= $${index} 
               AND s.sale_date < $${index + 1}::date + INTERVAL '1 day'`;
    values.push(from, to);
    index += 2;
  }

  // ✅ STATUS FILTER
  if (status) {
    if (status === "CANCELLED") {
      query += ` AND s.sale_status = 'voided'`;
    } else {
      query += ` AND s.sale_status != 'voided'
                 AND s.payment_status = $${index}`;
      values.push(status.toLowerCase());
      index++;
    }
  }

  query += ` ORDER BY s.sale_date DESC`;

  const r = await db.query(query, values);
  return r.rows;
};
