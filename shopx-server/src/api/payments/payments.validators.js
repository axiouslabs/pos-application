module.exports = {
  addPaymentValidator: (req, res, next) => {
    const { saleId, customerId, amount } = req.body;

    if (!saleId || !customerId || !amount) {
      res.status(400);
      throw new Error("saleId, customerId, and amount are required");
    }

    next();
  }
};
