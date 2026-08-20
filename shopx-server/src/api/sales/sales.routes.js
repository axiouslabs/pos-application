const express = require("express");
const router = express.Router();
const controller = require("./sales.controller");
const validateToken = require("../../middleware/validateTokenHandler");

router.post("/", validateToken, controller.createSale);
router.get("/", validateToken, controller.getAllSales);          // admin — all sales
router.get("/my", validateToken, controller.getMySales);         // salesperson — own sales
router.get("/customer/:customerId", validateToken, controller.getSalesByCustomer); // admin — by customer
router.get("/:id", validateToken, controller.getSaleById);       // single invoice
router.post("/:id/void", validateToken, controller.voidSale);


module.exports = router;
