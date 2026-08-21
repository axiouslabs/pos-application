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
  }
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
      payment_status
    ]
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
    ]
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
             c.phone AS customer_phone
      FROM sales s
      LEFT JOIN users u ON u.id = s.salesperson_id
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.id = $1
    `,
    [id]
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
  [id]
);


  const payments = await db.query(
    `SELECT * FROM payments WHERE sale_id = $1 ORDER BY created_at ASC`,
    [id]
  );

  return {
    sale: sale.rows[0],
    items: items.rows,
    payments: payments.rows,
  };
};


exports.getSaleById = async (client, id) => {
  const r = await client.query(
    `SELECT * FROM sales WHERE id = $1`,
    [id]
  );
  return r.rows[0];
};

exports.getSaleItems = async (client, saleId) => {
  const r = await client.query(
    `SELECT * FROM sale_items WHERE sale_id = $1`,
    [saleId]
  );
  return r.rows;
};


// BASIC LIST
exports.getAllSales = async (limit = 500) => {
  const r = await db.query(
    `
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
      c.phone AS customer_phone,
      COALESCE(
        json_agg(
          json_build_object(
            'id', p.id,
            'sale_id', p.sale_id,
            'customer_id', p.customer_id,
            'amount', p.amount,
            'method', p.method,
            'status', p.status,
            'created_at', p.created_at
          ) ORDER BY p.created_at ASC
        ) FILTER (WHERE p.id IS NOT NULL),
        '[]'
      ) AS payments
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    LEFT JOIN customers c ON c.id = s.customer_id
    LEFT JOIN payments p ON p.sale_id = s.id
    GROUP BY s.id, u.username, c.name, c.phone
    ORDER BY s.sale_date DESC
    LIMIT $1
    `,
    [limit]
  );

  return r.rows;
};

exports.getSalesBySalesperson = async (salespersonId, limit = 100) => {
  const r = await db.query(
    `
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
      c.phone AS customer_phone,
      COALESCE(
        json_agg(
          json_build_object(
            'id', p.id,
            'sale_id', p.sale_id,
            'customer_id', p.customer_id,
            'amount', p.amount,
            'method', p.method,
            'status', p.status,
            'created_at', p.created_at
          ) ORDER BY p.created_at ASC
        ) FILTER (WHERE p.id IS NOT NULL),
        '[]'
      ) AS payments
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    LEFT JOIN customers c ON c.id = s.customer_id
    LEFT JOIN payments p ON p.sale_id = s.id
    WHERE s.salesperson_id = $1
    GROUP BY s.id, u.username, c.name, c.phone
    ORDER BY s.sale_date DESC
    LIMIT $2
    `,
    [salespersonId, limit]
  );

  return r.rows;
};

exports.getSalesByCustomer = async (customerId) => {
  const r = await db.query(
    `
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
      c.name     AS customer_name,
      c.phone    AS customer_phone
    FROM sales s
    LEFT JOIN users u      ON u.id = s.salesperson_id
    LEFT JOIN customers c  ON c.id = s.customer_id
    WHERE s.customer_id = $1
    ORDER BY s.sale_date DESC
    `,
    [customerId]
  );

  return r.rows;
};

