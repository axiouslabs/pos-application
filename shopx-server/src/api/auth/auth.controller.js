// const asyncHandler = require("express-async-handler");
// const service = require("./auth.service");

// const registerUser = asyncHandler(async (req, res) => {
//   const user = await service.register(req.body, req.user);  // <-- Pass req.user
//   res.status(201).json({ message: "User registered successfully", user });
// });


// const loginUser = asyncHandler(async (req, res) => {
//   const result = await service.login(req.body);
//   res.json(result);
// });

// const loginAdmin = asyncHandler(async (req, res) => {
//   const result = await service.loginAdmin(req.body);
//   res.json(result);
// });


// const currentUser = asyncHandler(async (req, res) => {
//   res.json(req.user);
// });

// const updateUser = asyncHandler(async (req, res) => {
//   const updated = await service.updateUser(req.user.id, req.body);
//   res.json({ message: "User updated successfully", user: updated });
// });

// const getUserById = asyncHandler(async (req, res) => {
//   const user = await service.getUserById(req.params.id);
//   res.json(user);
// });

// const deleteUser = asyncHandler(async (req, res) => {
//   await service.deleteSelf(req.user.id);
//   res.json({ message: "User deleted successfully" });
// });

// const deleteUserByAdmin = asyncHandler(async (req, res) => {
//   const deleted = await service.deleteUserByAdmin(req.params.id);
//   res.json({
//     message: "User deleted successfully by admin",
//     deleted_user: deleted,
//   });
// });

// const getAllUsers = asyncHandler(async (req, res) => {
//   const users = await service.getAllUsers();
//   res.json({ message: "All users fetched successfully", users });
// });

// const loginOwner = asyncHandler(async (req, res) => {
//   const result = await service.loginOwner(req.body);
//   res.json(result);
// });

// const sendOTP = asyncHandler(async (req, res) => {
//   const userId = req.user.id; // now ALWAYS available
//   const { method } = req.body;

//   const result = await service.sendOTP({ userId, method });
//   res.json(result);
// });

// const verifyOTP = asyncHandler(async (req, res) => {
//   const userId = req.user.id; // works for both normal & tempToken
//   const { otp } = req.body;

//   const result = await service.verifyOTP({ userId, otp });
//   res.json(result);
// });

// // 🔁 Refresh access token using refresh token
// const refreshToken = asyncHandler(async (req, res) => {
//   const { refreshToken } = req.body;

//   if (!refreshToken) {
//     res.status(400);
//     throw new Error("Refresh token is required");
//   }

//   const result = await service.refreshAccessToken(refreshToken);
//   res.json(result);
// });



// module.exports = {
//   registerUser,
//   loginUser,
//   loginAdmin,
//   currentUser,
//   updateUser,
//   getUserById,
//   deleteUser,
//   deleteUserByAdmin,
//   getAllUsers,
//   loginOwner,
//   sendOTP,
//   verifyOTP,
//   refreshToken, 
// };



const asyncHandler = require("express-async-handler");
const service = require("./auth.service");

// ---------------- REGISTER ----------------
const registerUser = asyncHandler(async (req, res) => {
  const user = await service.register(req.body, req.user);
  res.status(201).json({
    message: "User registered successfully",
    user,
  });
});

// ---------------- LOGIN ----------------
const loginUser = asyncHandler(async (req, res) => {
  const result = await service.login(req.body);
  res.status(200).json(result);
});

const loginAdmin = asyncHandler(async (req, res) => {
  const result = await service.loginAdmin(req.body);
  res.status(200).json(result);
});

// ---------------- CURRENT USER ----------------
const currentUser = asyncHandler(async (req, res) => {
  res.status(200).json(req.user);
});

// ---------------- UPDATE USER ----------------
const updateUser = asyncHandler(async (req, res) => {
  const updated = await service.updateUser(req.user.id, req.body);
  res.status(200).json({
    message: "User updated successfully",
    user: updated,
  });
});

// ---------------- GET USERS ----------------
const getUserById = asyncHandler(async (req, res) => {
  const user = await service.getUserById(req.params.id);
  res.status(200).json(user);
});

const getAllUsers = asyncHandler(async (req, res) => {
  const users = await service.getAllUsers();
  res.status(200).json({
    message: "All users fetched successfully",
    users,
  });
});

// ---------------- DELETE ----------------
const deleteUser = asyncHandler(async (req, res) => {
  await service.deleteSelf(req.user.id);
  res.status(200).json({
    message: "User deleted successfully",
  });
});

const deleteUserByAdmin = asyncHandler(async (req, res) => {
  const deleted = await service.deleteUserByAdmin(req.params.id);
  res.status(200).json({
    message: "User deleted successfully by admin",
    deleted_user: deleted,
  });
});

// ---------------- OWNER LOGIN ----------------
const loginOwner = asyncHandler(async (req, res) => {
  const result = await service.loginOwner(req.body);
  res.status(200).json(result);
});

// ---------------- OTP ----------------
const sendOTP = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { method } = req.body;

  const result = await service.sendOTP({ userId, method });
  res.status(200).json(result);
});

const verifyOTP = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { otp } = req.body;

  const result = await service.verifyOTP({ userId, otp });
  res.status(200).json(result);
});

// ---------------- REFRESH TOKEN ----------------
const refreshToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({
      code: "REFRESH_TOKEN_REQUIRED",
      message: "Refresh token is required",
    });
  }

  const result = await service.refreshAccessToken(refreshToken);
  res.status(200).json(result);
});

// ---------------- LOGOUT ----------------
const logoutUser = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  await service.logout(refreshToken);

  res.status(200).json({
    message: "Logged out successfully",
  });
});

// ---------------- FORGOT PASSWORD ----------------
const forgotPassword = asyncHandler(async (req, res) => {
  const result = await service.forgotPassword(req.body);
  res.status(200).json(result);
});

const verifyResetOTP = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { otp } = req.body;

  const result = await service.verifyResetOTP({ userId, otp });
  res.status(200).json(result);
});

const resetPassword = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { newPassword } = req.body;

  const result = await service.resetPassword({ userId, newPassword });
  res.status(200).json(result);
});




module.exports = {
  registerUser,
  loginUser,
  loginAdmin,
  currentUser,
  updateUser,
  getUserById,
  deleteUser,
  deleteUserByAdmin,
  getAllUsers,
  loginOwner,
  sendOTP,
  verifyOTP,
  refreshToken,
  logoutUser,
  forgotPassword,
  verifyResetOTP,
  resetPassword,
};
