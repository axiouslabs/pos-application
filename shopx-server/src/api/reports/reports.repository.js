const db = require("../../config/db");

// ---------------------- SUMMARY ----------------------
exports.getSummary = async (start, end) => {
  const summary = await db.query(`
    SELECT 
      SUM(s.total_amount) AS revenue,
      SUM(si.quantity) AS units,
      AVG(s.total_amount) AS avg_value
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.sale_date BETWEEN $1 AND $2;
  `, [start, end]);

  const chart = await db.query(`
    SELECT 
      u.username AS name,
      SUM(s.total_amount) AS revenue
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    WHERE s.sale_date BETWEEN $1 AND $2
    GROUP BY u.username
    ORDER BY revenue DESC;
  `, [start, end]);

  return {
    summary: summary.rows[0],
    chart: chart.rows
  };
};

// ---------------------- SALESMAN PERFORMANCE ----------------------
exports.getSalesmanPerformance = async (start, end) => {
  const rows = await db.query(`
    SELECT 
      u.username AS name,
      SUM(s.total_amount) AS revenue,
      SUM(si.quantity) AS units
    FROM sales s
    LEFT JOIN users u ON u.id = s.salesperson_id
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.sale_date BETWEEN $1 AND $2
    GROUP BY u.username
    ORDER BY revenue DESC;
  `, [start, end]);

  return rows.rows;
};

// ---------------------- PRODUCT SALES ----------------------
exports.getProductSales = async (start, end) => {
  const rows = await db.query(`
    SELECT 
      p.name,
      SUM(si.total_price) AS revenue
    FROM sale_items si
    JOIN products p ON p.id = si.product_id
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date BETWEEN $1 AND $2
    GROUP BY p.name
    ORDER BY revenue DESC;
  `, [start, end]);

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

  const rows = await db.query(`
    SELECT 
      p.id AS product_id,
      p.name AS product_name,
      SUM(si.quantity) AS units_sold,
      SUM(si.total_price) AS revenue
    FROM sale_items si
    JOIN products p ON p.id = si.product_id
    JOIN sales s ON s.id = si.sale_id
   WHERE s.sale_date >= $1
      AND s.sale_date < ($2::date + INTERVAL '1 day')
    ${filter}
    GROUP BY p.id, p.name
    ORDER BY units_sold DESC;
  `, params);

  return rows.rows;
};


exports.getCustomerPerformance = async (start, end) => {
  const rows = await db.query(`
    SELECT 
      c.name AS customer,
      SUM(sa.total_amount) AS revenue,
      COUNT(sa.id) AS orders,
      SUM(si.quantity) AS units
    FROM sales sa
    LEFT JOIN sale_items si ON si.sale_id = sa.id
    JOIN customers c ON sa.customer_id = c.id
    WHERE sa.sale_date BETWEEN $1 AND $2
    GROUP BY c.name
    ORDER BY revenue DESC;
  `, [start, end]);

  return rows.rows;
};

