const express = require("express");
const router = express.Router();
const controller = require("./sales.controller");
const validateToken = require("../../middleware/validateTokenHandler");

router.post("/", validateToken, controller.createSale);
router.get("/", validateToken, controller.getAllSales);       // admin
router.get("/my", validateToken, controller.getMySales);     // Salesperson
router.get("/:id", validateToken, controller.getSaleById);
router.post("/:id/void", validateToken, controller.voidSale);
router.post("/:id/revise", validateToken, controller.reviseSale);


module.exports = router;
