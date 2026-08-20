const express = require("express");
const router = express.Router();
const ctrl = require("./stock.controller");
const validateToken = require("../../middleware/validateTokenHandler");
const checkAdmin = require("../../middleware/checkAdmin");

// admin adjusts stock
router.post("/adjust", validateToken, checkAdmin, ctrl.adjust);

// get stock for a product
router.get("/:id", validateToken, ctrl.getStock);

// get all stock (admin)
router.get("/", validateToken, checkAdmin, ctrl.getAll);

// get movements for a product
router.get("/:id/movements", validateToken, checkAdmin, ctrl.getMovements);

module.exports = router;
