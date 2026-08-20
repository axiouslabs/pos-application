const db = require("../../config/db");

module.exports = {
 getTotalSales: async () => {
  return await db.query(`
    SELECT 
      COUNT(id) AS total_sales,
      COALESCE(SUM(total_amount), 0) AS total_revenue,
      COALESCE(AVG(total_amount), 0) AS avg_order_value
    FROM sales
  `);
},


  getTotalPayments: async () => {
    return await db.query(`SELECT COALESCE(SUM(amount), 0) AS total_payments FROM payments`);
  },

  

  getCustomerCount: async () => {
  return await db.query(`SELECT COUNT(*) AS total_customers FROM customers`);
},



  getTodaySales: async () => {
    return await db.query(`
      SELECT COALESCE(SUM(total_amount), 0) AS today_sales
      FROM sales
      WHERE DATE(sale_date) = CURRENT_DATE
    `);
  },
getWeeklySales: async () => {
  return await db.query(`
    WITH days AS (
      SELECT unnest(ARRAY['MON','TUE','WED','THU','FRI','SAT','SUN']) AS day
    ),
    sales_data AS (
      SELECT 
        TO_CHAR(sale_date, 'DY') AS day,
        SUM(total_amount) AS revenue,
        COUNT(*) AS transactions
      FROM sales
      WHERE sale_date >= CURRENT_DATE - INTERVAL '6 days'
      GROUP BY TO_CHAR(sale_date, 'DY')
    )
    SELECT 
      d.day,
      COALESCE(s.revenue, 0) AS revenue,
      COALESCE(s.transactions, 0) AS transactions
    FROM days d
    LEFT JOIN sales_data s ON s.day = d.day
    ORDER BY array_position(
      ARRAY['MON','TUE','WED','THU','FRI','SAT','SUN'], d.day
    );
  `);
},



  getTopProducts: async () => {
    return await db.query(`
      SELECT p.name, SUM(si.quantity) AS total_qty
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      GROUP BY p.name
      ORDER BY total_qty DESC
      LIMIT 5
    `);
  },

  getSalesBySalesperson: async () => {
    return await db.query(`
      SELECT sp.name, COALESCE(SUM(s.total_amount),0) AS total_sales
      FROM salespersons sp
      LEFT JOIN sales s ON s.salesperson_id = sp.id
      GROUP BY sp.name
      ORDER BY total_sales DESC
    `);
  },

  getRecentSales: async () => {
    return await db.query(`
      SELECT s.id, s.total_amount, c.name AS customer, s.sale_date
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      ORDER BY s.sale_date DESC
      LIMIT 10
    `);
  },

  getLowStock: async () => {
    return await db.query(`
      SELECT p.name, s.quantity
      FROM stock s
      JOIN products p ON p.id = s.product_id
      WHERE s.quantity < 10
      ORDER BY s.quantity ASC
    `);
  },

  getTotalDiscount: async () => {
  return await db.query(`
    SELECT 
      COALESCE(SUM(quantity * discount), 0) AS total_discount
    FROM sale_items
  `);
},

};
