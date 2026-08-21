const express = require("express");
const router = express.Router();

const controller = require("./payments.controller");
const { addPaymentValidator } = require("./payments.validators");
const validateToken = require("../../middleware/validateTokenHandler");

router.post("/", validateToken, addPaymentValidator, controller.addPayment);
router.get("/:saleId", validateToken, controller.getPayments);
router.get("/:saleId/summary", validateToken, controller.getPaymentSummary);
router.post("/:saleId/mark-paid", validateToken, controller.markPaymentAsPaid);
router.post("/:saleId/partial-payment", validateToken, controller.addPartialPayment);
router.patch("/:saleId/mark-pending", validateToken, controller.markPaymentAsPending);
router.patch("/:saleId/mark-partial", validateToken, controller.markPaymentAsPartial);

module.exports = router;
