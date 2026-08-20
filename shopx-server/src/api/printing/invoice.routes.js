const express = require("express");
const router = express.Router();
const controller = require("./invoice.controller");
const validateToken = require("../../middleware/validateTokenHandler");

router.get("/:saleId/pdf", validateToken, controller.getInvoicePDF);
router.get("/:saleId/receipt", validateToken, controller.getReceiptData);


module.exports = router;
