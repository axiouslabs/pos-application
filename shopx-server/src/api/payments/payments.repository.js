const db = require("../../config/db");

module.exports = {
  // ✅ Create payment (paid OR pending)
  createPayment: async (
    client,
    { saleId, customerId, amount, method, status }
  ) => {
    return await client.query(
      `INSERT INTO payments (sale_id, customer_id, amount, method, status)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [saleId, customerId, amount, method, status]
    );
  },

  // ✅ Get all payments of a sale
  getPaymentsBySale: async (saleId) => {
    return await db.query(
      `SELECT * FROM payments WHERE sale_id = $1 ORDER BY created_at ASC`,
      [saleId]
    );
  },

  // ✅ Mark ALL pending payments of a sale as PAID
 markPaymentsAsPaid: async (client, saleId) => {
  return await client.query(
    `UPDATE payments
     SET status = 'paid'
     WHERE sale_id = $1 AND status = 'pending'`,
    [saleId]
  );
},


  // ✅ Reverse payments when sale is voided
  reversePaymentBySaleId: async (client, saleId) => {
    return await client.query(
      `UPDATE payments
       SET status = 'reversed'
       WHERE sale_id = $1 AND status = 'paid'`,
      [saleId]
    );
  },

  // ✅ Update sale payment status (paid / pending / partially_paid)
  updateSalePaymentStatus: async (saleId, status) => {
    return await db.query(
      `UPDATE sales SET payment_status = $1 WHERE id = $2`,
      [status, saleId]
    );
  },

  // ================= SALE BALANCE =================

  // Get sale balance
  getSaleBalance: async (saleId) => {
    const r = await db.query(
      `SELECT * FROM sale_balance WHERE sale_id = $1`,
      [saleId]
    );
    return r.rows[0] || null;
  },

  // Create or update sale balance
  upsertSaleBalance: async (client, saleId, totalAmount, paidAmount) => {
    const balance = totalAmount - paidAmount;
    return await client.query(
      `INSERT INTO sale_balance (sale_id, total_amount, paid_amount, balance)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (sale_id)
       DO UPDATE SET paid_amount = $3, balance = $4`,
      [saleId, totalAmount, paidAmount, balance]
    );
  },

  // Get total paid amount for a sale
  getTotalPaidAmount: async (client, saleId) => {
    const r = await client.query(
      `SELECT COALESCE(SUM(amount), 0) AS total_paid
       FROM payments
       WHERE sale_id = $1 AND status = 'paid'`,
      [saleId]
    );
    return parseFloat(r.rows[0].total_paid);
  },
};
