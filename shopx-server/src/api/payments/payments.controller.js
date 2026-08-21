const asyncHandler = require("express-async-handler");
const service = require("./payments.service");

// ✅ Create payment (paid OR pending)
exports.addPayment = asyncHandler(async (req, res) => {
  const { saleId, customerId, amount, method, status } = req.body;

  const result = await service.addPayment({
    saleId,
    customerId,
    amount,
    method,
    status,
  });

  res.json(result);
});

// ✅ Get all payments of a sale
exports.getPayments = asyncHandler(async (req, res) => {
  const { saleId } = req.params;

  const payments = await service.getPaymentsOfSale(saleId);
  res.json(payments.rows);
});

// ✅ Get payment summary (total, paid, balance, status)
exports.getPaymentSummary = asyncHandler(async (req, res) => {
  const { saleId } = req.params;

  const summary = await service.getPaymentSummary(saleId);
  res.json(summary);
});

// ✅ Mark pending/partially_paid → fully paid
exports.markPaymentAsPaid = asyncHandler(async (req, res) => {
  const { saleId } = req.params;

  const result = await service.markPaymentAsPaid(saleId);

  res.json({
    message: "Payment marked as PAID",
    result,
  });
});

// ✅ Add partial payment
exports.addPartialPayment = asyncHandler(async (req, res) => {
  const { saleId } = req.params;
  const { customerId, amount, method } = req.body;

  if (!amount || amount <= 0) {
    res.status(400);
    throw new Error("Payment amount must be greater than 0");
  }

  const result = await service.addPartialPayment({
    saleId: parseInt(saleId),
    customerId,
    amount: parseFloat(amount),
    method,
  });

  res.json(result);
});

// ✅ Downgrade paid → pending (clears all payments for this sale)
exports.markPaymentAsPending = asyncHandler(async (req, res) => {
  const { saleId } = req.params;
  const result = await service.markPaymentAsPending(parseInt(saleId));
  res.json({ message: "Payment status set to PENDING", result });
});

// ✅ Downgrade paid → partially_paid (retains a specific paid amount)
exports.markPaymentAsPartial = asyncHandler(async (req, res) => {
  const { saleId } = req.params;
  const { paid_amount } = req.body;

  if (paid_amount == null || paid_amount <= 0) {
    res.status(400);
    throw new Error("paid_amount must be greater than 0");
  }

  const result = await service.markPaymentAsPartial({
    saleId: parseInt(saleId),
    paidAmount: parseFloat(paid_amount),
  });

  res.json(result);
});
