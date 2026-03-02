const db = require("../../config/db");

// ---------------------- SUMMARY ----------------------
exports.getSummary = async (start, end) => {
  const summary = await db.query(
    `
SELECT 
  SUM(s.total_amount) AS revenue,
  (
    SELECT SUM(quantity)
    FROM sale_items si
    JOIN sales s2 ON s2.id = si.sale_id
   WHERE s2.sale_date >= $1
AND s2.sale_date < ($2::date + INTERVAL '1 day')
      AND s2.payment_status = 'paid'
      AND s2.sale_status != 'voided'
  ) AS units,
  AVG(s.total_amount) AS avg_value
FROM sales s
WHERE s.sale_date >= $1
AND s.sale_date < ($2::date + INTERVAL '1 day')
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided';

  `,
    [start, end],
  );
  const chart = await db.query(
    `
   SELECT 
    u.username AS name,
    SUM(s.total_amount) AS revenue
  FROM sales s
  LEFT JOIN users u 
    ON u.id = s.salesperson_id 
   AND u.is_active = true
 WHERE s.sale_date >= $1
  AND s.sale_date < ($2::date + INTERVAL '1 day')
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
  GROUP BY u.id, u.username
  ORDER BY revenue DESC;

`,
    [start, end],
  );

  return {
    summary: summary.rows[0],
    chart: chart.rows,
  };
};

// ---------------------- SALESMAN PERFORMANCE ----------------------
exports.getSalesmanPerformance = async (start, end) => {
  const rows = await db.query(
    `
  SELECT 
  u.username AS name,
  SUM(s.total_amount) AS revenue,
  (
    SELECT SUM(si.quantity)
    FROM sale_items si
    WHERE si.sale_id IN (
      SELECT id FROM sales s2
      WHERE s2.salesperson_id = u.id
       AND s2.sale_date >= $1
    AND s2.sale_date < ($2::date + INTERVAL '1 day')
        AND s2.payment_status = 'paid'
        AND s2.sale_status != 'voided'
    )
  ) AS units
FROM sales s
LEFT JOIN users u 
  ON u.id = s.salesperson_id
 AND u.is_active = true
WHERE s.sale_date >= $1
AND s.sale_date < ($2::date + INTERVAL '1 day')
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
GROUP BY u.id, u.username
ORDER BY revenue DESC;


  `,
    [start, end],
  );

  return rows.rows;
};

// ---------------------- PRODUCT SALES ----------------------
exports.getProductSales = async (start, end) => {
  const rows = await db.query(
    `
    SELECT 
      p.name,
      SUM(si.total_price) AS revenue
    FROM sale_items si
   JOIN products p 
  ON p.id = si.product_id
 AND p.is_active = true
    JOIN sales s ON s.id = si.sale_id
  WHERE s.sale_date >= $1
AND s.sale_date < ($2::date + INTERVAL '1 day')
AND s.payment_status = 'paid'
AND s.sale_status != 'voided'
    GROUP BY p.name
    ORDER BY revenue DESC;
  `,
    [start, end],
  );

  return rows.rows;
};

// ---------------------- PRODUCT PERFORMANCE ----------------------
exports.getProductPerformance = async (start, end, salespersonId = null) => {
  const params = [start, end];
  let filter = "";

  if (salespersonId) {
    params.push(salespersonId);
    filter = "AND s.salesperson_id = $3";
  }

  const rows = await db.query(
    `
    SELECT 
      p.id AS product_id,
      p.name AS product_name,
      SUM(si.quantity) AS units_sold,
      SUM(
  (si.total_price / s.subtotal_amount) * s.total_amount
) AS revenue
    FROM sale_items si
   JOIN products p 
  ON p.id = si.product_id
 AND p.is_active = true 
    JOIN sales s ON s.id = si.sale_id
  WHERE s.sale_date >= $1
  AND s.sale_date < ($2::date + INTERVAL '1 day')
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
    ${filter}
    GROUP BY p.id, p.name
    ORDER BY units_sold DESC;
  `,
    params,
  );

  return rows.rows;
};






// exports.getCustomerPerformance = async (start, end) => {
//   const rows = await db.query(
//     `
//   SELECT 
//   c.name AS customer,
//   SUM(sa.total_amount) AS revenue,
//   COUNT(sa.id) AS orders,
//   SUM(si.quantity) AS units
// FROM sales sa
// LEFT JOIN sale_items si ON si.sale_id = sa.id
// JOIN customers c 
//   ON sa.customer_id = c.id
//  AND c.is_active = true
// WHERE sa.sale_date >= $1
//   AND sa.sale_date < ($2::date + INTERVAL '1 day')
//   AND sa.payment_status = 'paid'
//   AND sa.sale_status != 'voided'
// GROUP BY c.name
// ORDER BY revenue DESC;

//   `,
//     [start, end],
//   );

//   return rows.rows;
// };


exports.getCustomerPerformance = async (start, end) => {
  const rows = await db.query(
    `
    SELECT 
      c.name AS customer,
      SUM(sa.total_amount) AS revenue,
      COUNT(sa.id) AS orders,
      SUM(COALESCE(si.total_units, 0)) AS units
    FROM sales sa
    JOIN customers c 
      ON sa.customer_id = c.id
     AND c.is_active = true

    -- aggregate sale_items FIRST
    LEFT JOIN (
        SELECT sale_id, SUM(quantity) AS total_units
        FROM sale_items
        GROUP BY sale_id
    ) si ON si.sale_id = sa.id

    WHERE sa.sale_date >= $1
      AND sa.sale_date < ($2::date + INTERVAL '1 day')
      AND sa.payment_status = 'paid'
      AND sa.sale_status != 'voided'

    GROUP BY c.name
    ORDER BY revenue DESC;
    `,
    [start, end]
  );

  return rows.rows;
};



/*
const db = require("../../config/db");

// ---------------------- SUMMARY ----------------------
exports.getSummary = async (start, end) => {
  const summary = await db.query(
    `
   SELECT 
  SUM(s.subtotal_amount - s.discount_amount) AS revenue,
  SUM(si.quantity) AS units,
  AVG(s.subtotal_amount - s.discount_amount) AS avg_value
FROM sales s
LEFT JOIN sale_items si ON si.sale_id = s.id
WHERE s.sale_date BETWEEN $1 AND $2
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided';

  `,
    [start, end],
  );
  const chart = await db.query(
    `
  SELECT 
    u.username AS name,
    SUM(s.subtotal_amount - s.discount_amount) AS revenue
  FROM sales s
 LEFT JOIN users u 
  ON u.id = s.salesperson_id 
 AND u.is_active = true
  WHERE s.sale_date BETWEEN $1 AND $2
    AND s.payment_status = 'paid'
    AND s.sale_status != 'voided'
 GROUP BY u.id, u.username
ORDER BY revenue DESC;

`,
    [start, end],
  );

  return {
    summary: summary.rows[0],
    chart: chart.rows,
  };
};

// ---------------------- SALESMAN PERFORMANCE ----------------------
exports.getSalesmanPerformance = async (start, end) => {
  const rows = await db.query(
    `
   SELECT 
  u.username AS name,
  SUM(s.subtotal_amount - s.discount_amount) AS revenue,
  SUM(si.quantity) AS units
FROM sales s
LEFT JOIN users u 
  ON u.id = s.salesperson_id
 AND u.is_active = true
LEFT JOIN sale_items si ON si.sale_id = s.id
WHERE s.sale_date BETWEEN $1 AND $2
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
GROUP BY u.id, u.username
ORDER BY revenue DESC;


  `,
    [start, end],
  );

  return rows.rows;
};

// ---------------------- PRODUCT SALES ----------------------
exports.getProductSales = async (start, end) => {
  const rows = await db.query(
    `
    SELECT 
      p.name,
      SUM(si.total_price) AS revenue
    FROM sale_items si
   JOIN products p 
  ON p.id = si.product_id
 AND p.is_active = true
    JOIN sales s ON s.id = si.sale_id
  WHERE s.sale_date BETWEEN $1 AND $2
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
    GROUP BY p.name
    ORDER BY revenue DESC;
  `,
    [start, end],
  );

  return rows.rows;
};

// ---------------------- PRODUCT PERFORMANCE ----------------------
exports.getProductPerformance = async (start, end, salespersonId = null) => {
  const params = [start, end];
  let filter = "";

  if (salespersonId) {
    params.push(salespersonId);
    filter = "AND s.salesperson_id = $3";
  }

  const rows = await db.query(
    `
    SELECT 
      p.id AS product_id,
      p.name AS product_name,
      SUM(si.quantity) AS units_sold,
      SUM(si.total_price) AS revenue
    FROM sale_items si
   JOIN products p 
  ON p.id = si.product_id
 AND p.is_active = true
    JOIN sales s ON s.id = si.sale_id
  WHERE s.sale_date >= $1
  AND s.sale_date < ($2::date + INTERVAL '1 day')
  AND s.payment_status = 'paid'
  AND s.sale_status != 'voided'
    ${filter}
    GROUP BY p.id, p.name
    ORDER BY units_sold DESC;
  `,
    params,
  );

  return rows.rows;
};

exports.getCustomerPerformance = async (start, end) => {
  const rows = await db.query(
    `
  SELECT 
  c.name AS customer,
  SUM(sa.subtotal_amount - sa.discount_amount) AS revenue,
  COUNT(sa.id) AS orders,
  SUM(si.quantity) AS units
FROM sales sa
LEFT JOIN sale_items si ON si.sale_id = sa.id
JOIN customers c 
  ON sa.customer_id = c.id
 AND c.is_active = true
WHERE sa.sale_date BETWEEN $1 AND $2
  AND sa.payment_status = 'paid'
  AND sa.sale_status != 'voided'
GROUP BY c.name
ORDER BY revenue DESC;

  `,
    [start, end],
  );

  return rows.rows;
};
*/