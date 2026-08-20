const express = require("express");
const router = express.Router();

// Import the controller that handles the business logic for each route
const controller = require("./products.controller");

// Import validation middleware to check if incoming data is valid
const {
  validateCreateProduct,
  validateUpdateProduct,
} = require("./products.validator");

// Import authentication and authorization middleware
const validateToken = require("../../middleware/validateTokenHandler");
const checkAdmin = require("../../middleware/checkAdmin");

// Public
router.get("/", controller. getAllProducts);
router.get("/:id", controller. getProductById);

//Admin Only

const uploadProductImage = require("../../middleware/uploadProductImage");

// 1️⃣ Create product (JSON only, no images)
router.post(
  "/",
  validateToken,
  checkAdmin,
  validateCreateProduct,
  controller.createProduct
);

// 2️⃣ Upload images separately
router.post(
  "/:id/images",
  validateToken,
  checkAdmin,
  uploadProductImage.array("images", 5),
  controller.uploadImages
);


  
router.put(
  "/:id",
  validateToken,
  checkAdmin,
  validateUpdateProduct,
  controller.updateProduct
);

router.delete("/:id", validateToken, checkAdmin, controller.deleteProduct);

router.post(
  "/:id/adjust-stock",
  validateToken,
  checkAdmin,
  controller.adjustStock
);

module.exports = router;
