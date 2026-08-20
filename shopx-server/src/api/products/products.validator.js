exports.validateCreateProduct = (req, res, next) => {
  const { name, name_ar, price, quantity, category, code, vat } = req.body;

  if (!name || !name_ar || !price || !category || !code || vat == null) {
    return res.status(400).json({
      message: "name, name_ar, price, category, code, vat are required",
    });
  }

  next();
};

// VALIDATE UPDATE PRODUCT - allow any one field except unit
exports.validateUpdateProduct = (req, res, next) => {
  if (
    req.body.name == null &&
    req.body.name_ar == null &&
    req.body.price == null &&
    req.body.category == null &&
    req.body.code == null &&
    req.body.vat == null
  ) {
    return res.status(400).json({
      message:
        "At least one field (name / price / category / code / vat) must be provided",
    });
  }

  next();
};
