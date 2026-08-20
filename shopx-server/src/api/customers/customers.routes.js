const express = require("express");
const router = express.Router();
const controller = require("./customers.controller");
const validateToken = require("../../middleware/validateTokenHandler");
const checkAdmin = require("../../middleware/checkAdmin");

// Admin + sales can add customers
router.post("/", validateToken, controller.createCustomer);

// Admin + sales get all customers
router.get("/", validateToken, controller.getAllCustomers);

// Salesperson: get only my customers
router.get("/my", validateToken, controller.getMyCustomers);


// Get customer by id
router.get("/:id", validateToken, controller.getCustomerById);


// Update customer
router.put("/:id", validateToken, checkAdmin, controller.updateCustomer);

// Delete customer (admin only)
router.delete("/:id", validateToken, checkAdmin, controller.deleteCustomer);

module.exports = router;
