const repo = require("./payments.repository");
const db = require("../../config/db");

// ✅ ADD PAYMENT (PAID or PENDING)
exports.addPayment = async ({ saleId, customerId, amount, method, status }) => {
  const client = await db.connect();
  const paymentStatus = status || "paid";

  try {
    await client.query("BEGIN");

    const payment = await repo.createPayment(client, {
      saleId,
      customerId,
      amount,
      method,
      status: paymentStatus,
    });

    await repo.updateSalePaymentStatus(saleId, paymentStatus);

    await client.query("COMMIT");

    return {
      payment: payment.rows[0],
      payment_status: paymentStatus,
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

// ✅ ADD PARTIAL PAYMENT (record a portion of the total)
exports.addPartialPayment = async ({ saleId, customerId, amount, method }) => {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    // Get total sale amount
    const saleRes = await client.query(
      `SELECT total_amount FROM sales WHERE id = $1`,
      [saleId]
    );

    if (!saleRes.rows[0]) throw new Error("Sale not found");
    const totalAmount = parseFloat(saleRes.rows[0].total_amount);

    // Record the payment as paid
    await repo.createPayment(client, {
      saleId,
      customerId,
      amount,
      method: method || "cash",
      status: "paid",
    });

    // Calculate total paid so far
    const totalPaid = await repo.getTotalPaidAmount(client, saleId);

    // Update sale_balance
    await repo.upsertSaleBalance(client, saleId, totalAmount, totalPaid);

    // Determine payment status
    let newStatus;
    if (totalPaid >= totalAmount) {
      newStatus = "paid";
    } else {
      newStatus = "partially_paid";
    }

    await repo.updateSalePaymentStatus(saleId, newStatus);

    await client.query("COMMIT");

    return {
      saleId,
      total_amount: totalAmount,
      paid_amount: totalPaid,
      balance: totalAmount - totalPaid,
      payment_status: newStatus,
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

// ✅ Mark pending → paid (used after 4–5 days)
exports.markPaymentAsPaid = async (saleId) => {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    // Get total sale amount
    const saleRes = await client.query(
      `SELECT total_amount FROM sales WHERE id = $1`,
      [saleId]
    );
    if (!saleRes.rows[0]) throw new Error("Sale not found");
    const totalAmount = parseFloat(saleRes.rows[0].total_amount);

    // Mark all pending payments as PAID
    await repo.markPaymentsAsPaid(client, saleId);

    // Calculate total paid
    const totalPaid = await repo.getTotalPaidAmount(client, saleId);

    // If partially_paid and marking as paid, record remaining as a new payment
    if (totalPaid < totalAmount) {
      const remaining = totalAmount - totalPaid;

      // Get customer_id from sale
      const saleDetail = await client.query(
        `SELECT customer_id FROM sales WHERE id = $1`,
        [saleId]
      );

      await repo.createPayment(client, {
        saleId,
        customerId: saleDetail.rows[0].customer_id,
        amount: remaining,
        method: "cash",
        status: "paid",
      });
    }

    // Update sale_balance to fully paid
    await repo.upsertSaleBalance(client, saleId, totalAmount, totalAmount);

    // Update sale payment status to paid
    await repo.updateSalePaymentStatus(saleId, "paid");

    await client.query("COMMIT");

    return {
      saleId,
      payment_status: "paid",
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

// ✅ Get payment summary for a sale
exports.getPaymentSummary = async (saleId) => {
  const payments = await repo.getPaymentsBySale(saleId);
  const balance = await repo.getSaleBalance(saleId);

  // Get sale total
  const saleRes = await db.query(
    `SELECT total_amount, payment_status FROM sales WHERE id = $1`,
    [saleId]
  );

  if (!saleRes.rows[0]) throw new Error("Sale not found");

  const sale = saleRes.rows[0];
  const totalAmount = parseFloat(sale.total_amount);

  // Calculate from payments if balance record doesn't exist
  let paidAmount = 0;
  if (balance) {
    paidAmount = parseFloat(balance.paid_amount);
  } else {
    // Sum paid payments
    paidAmount = payments.rows
      .filter((p) => p.status === "paid")
      .reduce((sum, p) => sum + parseFloat(p.amount), 0);
  }

  return {
    sale_id: parseInt(saleId),
    total_amount: totalAmount,
    paid_amount: paidAmount,
    balance: totalAmount - paidAmount,
    payment_status: sale.payment_status,
    payments: payments.rows,
  };
};

exports.getPaymentsOfSale = async (saleId) => {
  return await repo.getPaymentsBySale(saleId);
};

// ✅ Downgrade paid → pending (delete all payment records, reset balance)
exports.markPaymentAsPending = async (saleId) => {
  const client = await db.connect();
  try {
    await client.query("BEGIN");

    // Delete all payments for this sale
    await client.query(`DELETE FROM payments WHERE sale_id = $1`, [saleId]);

    // Reset sale_balance to 0 paid
    const saleRes = await client.query(
      `SELECT total_amount FROM sales WHERE id = $1`,
      [saleId]
    );
    if (!saleRes.rows[0]) throw new Error("Sale not found");
    const totalAmount = parseFloat(saleRes.rows[0].total_amount);

    await repo.upsertSaleBalance(client, saleId, totalAmount, 0);

    // Set sale payment_status to pending
    await repo.updateSalePaymentStatus(saleId, "pending");

    await client.query("COMMIT");
    return { saleId, payment_status: "pending" };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

// ✅ Downgrade paid → partially_paid (set a specific paid amount, rest becomes balance)
exports.markPaymentAsPartial = async ({ saleId, paidAmount }) => {
  const client = await db.connect();
  try {
    await client.query("BEGIN");

    const saleRes = await client.query(
      `SELECT total_amount, customer_id FROM sales WHERE id = $1`,
      [saleId]
    );
    if (!saleRes.rows[0]) throw new Error("Sale not found");
    const totalAmount = parseFloat(saleRes.rows[0].total_amount);
    const customerId = saleRes.rows[0].customer_id;

    if (paidAmount >= totalAmount) {
      throw new Error("Paid amount must be less than total. Use mark-paid instead.");
    }

    // Delete existing payments and create a fresh one for the declared paid amount
    await client.query(`DELETE FROM payments WHERE sale_id = $1`, [saleId]);

    await repo.createPayment(client, {
      saleId,
      customerId,
      amount: paidAmount,
      method: "cash",
      status: "paid",
    });

    // Update sale_balance
    await repo.upsertSaleBalance(client, saleId, totalAmount, paidAmount);

    // Set status to partially_paid
    await repo.updateSalePaymentStatus(saleId, "partially_paid");

    await client.query("COMMIT");
    return {
      saleId,
      total_amount: totalAmount,
      paid_amount: paidAmount,
      balance: totalAmount - paidAmount,
      payment_status: "partially_paid",
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};
