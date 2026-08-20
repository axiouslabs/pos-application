// const express = require("express");
// const controller = require("./auth.controller");
// const validateToken = require("../../middleware/validateTokenHandler");
// const checkAdmin = require("../../middleware/checkAdmin");
// const { registerValidator, loginValidator } = require("./auth.validator");

// const router = express.Router();


// // Admin-only routes
// router.post("/register", validateToken, checkAdmin, registerValidator, controller.registerUser);
// router.post("/login-owner", loginValidator, controller.loginOwner);

// // Admin login route (NEW)
// router.post("/admin/login", loginValidator, controller.loginAdmin);


// // Public
// router.post("/login", loginValidator, controller.loginUser);

// // 🔁 REFRESH ACCESS TOKEN
// router.post("/refresh-token", controller.refreshToken);


// // Protected
// router.get("/current", validateToken, controller.currentUser);
// router.put("/update", validateToken, controller.updateUser);
// router.delete("/delete", validateToken, controller.deleteUser);
// router.post("/send-otp", validateToken, controller.sendOTP);
// router.post("/verify-otp", validateToken, controller.verifyOTP);

// // Admin
// router.get("/users", validateToken, checkAdmin, controller.getAllUsers);
// router.get("/user/:id", validateToken, checkAdmin, controller.getUserById);
// router.delete(
//   "/user/:id",
//   validateToken,
//   checkAdmin,
//   controller.deleteUserByAdmin
// );

// module.exports = router;

const express = require("express");
const controller = require("./auth.controller");
const validateToken = require("../../middleware/validateTokenHandler");
const checkAdmin = require("../../middleware/checkAdmin");
const { registerValidator, loginValidator } = require("./auth.validator");

const router = express.Router();

// ---------------- PUBLIC ----------------
router.post("/login", loginValidator, controller.loginUser);
router.post("/admin/login", loginValidator, controller.loginAdmin);
router.post("/login-owner", loginValidator, controller.loginOwner);
router.post("/forgot-password", controller.forgotPassword);

// 🔁 REFRESH (MUST ALWAYS BE PUBLIC)
router.post("/refresh-token", controller.refreshToken);

// ---------------- PROTECTED ----------------
router.get("/current", validateToken, controller.currentUser);
router.put("/update", validateToken, controller.updateUser);
router.delete("/delete", validateToken, controller.deleteUser);
router.post("/send-otp", validateToken, controller.sendOTP);
router.post("/verify-otp", validateToken, controller.verifyOTP);
router.post("/verify-reset-otp", validateToken, controller.verifyResetOTP);
router.post("/reset-password", validateToken, controller.resetPassword);

// 🔓 LOGOUT (USER-INITIATED ONLY)
router.post("/logout", validateToken, controller.logoutUser);

// ---------------- ADMIN ----------------
router.post("/register", validateToken, checkAdmin, registerValidator, controller.registerUser);
router.get("/users", validateToken, checkAdmin, controller.getAllUsers);
router.get("/user/:id", validateToken, checkAdmin, controller.getUserById);
router.delete("/user/:id", validateToken, checkAdmin, controller.deleteUserByAdmin);

module.exports = router;
