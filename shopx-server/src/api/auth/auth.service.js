const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const repo = require("./auth.repository");
// const otpRepo = require("./auth.repository");
const { sendEmail } = require("../../utils/email"); // ✅ ADD
const { sendWhatsAppOtp } = require("../../utils/whatsapp");
const { generateOTP } = require("../../utils/otp");
const { sendSMS } = require("../../utils/sms");
const crypto = require("crypto");

// 🔁 Generate refresh token (random, secure)
const generateRefreshToken = () => {
  return crypto.randomBytes(40).toString("hex");
};

const register = async (data, reqUser) => {
  const { username, email, password, phone, user_type } = data;

  if (!username || !email || !password || !phone) {
    throw new Error("ALL fields are mandatory");
  }

  // 🔥 Check if any admin exists
  const adminCount = await repo.countAdmins();

  let finalType;

  // First user EVER → admin
  if (adminCount === 0) {
    finalType = "admin";
  } else {
    // If admin exists → only admin can register new accounts
    if (!reqUser || reqUser.user_type !== "admin") {
      throw new Error("Only admin can create new accounts");
    }
    // If admin sets user_type=admin → create admin
    // else create normal user
    finalType = user_type === "admin" ? "admin" : "user";
  }

  const existing = await repo.findUserByEmail(email);
  if (existing) throw new Error("User Already Registered!");

  const passwordHash = await bcrypt.hash(password, 10);

  const user = await repo.createUser({
    username,
    email,
    passwordHash,
    phone,
    user_type: finalType,
  });

  return {
    id: user.id,
    username: user.username,
    email: user.email,
    user_type: user.user_type,
    phone: user.phone,
  };
};

const login = async ({ username, password }) => {
  if (!username || !password) throw new Error("All fields are Mandatory");

  const user = await repo.findUserByUsername(username);
  if (!user) throw new Error("Invalid credentials");

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error("Invalid credentials");

  // 🚨 BLOCK ADMINS FROM EMPLOYEE LOGIN
  if (user.user_type === "admin") {
    throw new Error("Admins must login through admin route");
  }

  const accessToken = jwt.sign(
    {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        user_type: user.user_type,
      },
    },
    process.env.ACCESS_TOKEN_SECRET,
    // { expiresIn: "1d" }
    { expiresIn: "50m" } // ⏱ TEMP: for refresh-token testing
  );

  // 🔐 Ensure single active session
  // await repo.deleteRefreshTokensByUser(user.id);

  // 🔽 ADD BELOW (DO NOT REMOVE EXISTING CODE)
  const refreshToken = generateRefreshToken();
  await repo.saveRefreshToken(user.id, refreshToken);

  // return { accessToken };

  // ✅ CRUCIAL FIX: Return BOTH token AND user data
  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      user_type: user.user_type, // 🔵 Flutter needs this!
    },
  };
};

const loginAdmin = async ({ username, password }) => {
  if (!username || !password) throw new Error("All fields are mandatory");

  const user = await repo.findUserByUsername(username);
  if (!user) throw new Error("Invalid credentials");

  if (user.user_type !== "admin") {
    throw new Error("Not authorized. Only admin can login.");
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error("Invalid credentials");

  const accessToken = jwt.sign(
    {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        user_type: user.user_type,
      },
    },
    process.env.ACCESS_TOKEN_SECRET,
    // { expiresIn: "1d" }
    { expiresIn: "50m" } // ⏱ TEMP: for refresh-token testing
  );

  const refreshToken = generateRefreshToken();
  await repo.saveRefreshToken(user.id, refreshToken);

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      user_type: user.user_type,
    },
  };
};

const updateUser = async (userId, { username, email }) => {
  if (!username && !email) throw new Error("Provide username or email");

  if (email) {
    const check = await repo.findUserByEmail(email);
    if (check && check.id !== userId) throw new Error("Email already in use");
  }

  const updated = await repo.updateUser(userId, username, email);
  if (!updated) throw new Error("User not found");

  return updated;
};

const getUserById = async (id) => {
  const user = await repo.findUserById(id);
  if (!user) throw new Error("User not found");
  return user;
};

const deleteSelf = async (userId) => {
  const deleted = await repo.deleteUserById(userId);
  if (!deleted) throw new Error("User not found");
};

const deleteUserByAdmin = async (id) => {
  const deleted = await repo.deleteUserById(id);
  if (!deleted) throw new Error("User not found");
  return deleted;
};

const getAllUsers = async () => {
  return await repo.getAllUsers();
};

//ownerLogin
const loginOwner = async ({ username, password }) => {
  const user = await repo.findUserByUsername(username);

  if (!user) throw new Error("user not found ");
  if (user.user_type !== "admin")
    throw new Error("Not authorized. Only admin can login.");

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error("Invalid credentials");

  // Temporary short-lived token (5 min)
  const tempToken = jwt.sign({ id: user.id }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "50m",
  });

  return { tempToken };
};

const sendOTP = async ({ userId, method }) => {
  // normalize method names
  method = method.toLowerCase().replace(" ", "_");

  const user = await repo.findUserById(userId);
  if (!user) throw new Error("User not found");

  const otp = generateOTP();

  await repo.saveOTP(user.id, otp, method);

  // EMAIL OTP (FREE - WORKS NOW)
  if (method === "email") {
    if (!user.email) throw new Error("User email not found");
    await sendEmail(user.email, otp);
  }

  // 🟢 WHATSAPP OTP (FREE TRIAL)
  else if (method === "whatsapp") {
    if (!user.phone) throw new Error("User phone number not found");
    await sendWhatsAppOtp(user.phone, otp);
  }

  // 🔴 SMS OTP (REQUIRES PAID TWILIO)
  else if (method === "sms") {
    if (!user.phone) throw new Error("User phone number not found");
    await sendSMS(user.phone, `Your login OTP is: ${otp}`);
  } else {
    throw new Error("Invalid OTP method. Use: email, whatsapp, or sms"); // ✅ ADDED: Error for invalid methods
  }

  return {
    message: "OTP sent successfully",
    method: method,
    destination: method === "email" ? user.email : user.phone, // ✅ ADDED: Return destination info
  };
};

const verifyOTP = async ({ userId, otp }) => {
  const found = await repo.findValidOTP(userId, otp);
  if (!found) throw new Error("Invalid or expired OTP");

  await repo.deleteOTP(userId);

  const user = await repo.findUserById(userId);

  const accessToken = jwt.sign(
    {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        user_type: user.user_type, // Full user information
      },
    },
    process.env.ACCESS_TOKEN_SECRET, // Secret key
    // { expiresIn: "1d" } // Token valid for 24 hours
    { expiresIn: "50m" } // ⏱ TEMP: for refresh-token testing
  );

  // await repo.deleteRefreshTokensByUser(user.id);

  const refreshToken = generateRefreshToken();
  await repo.saveRefreshToken(user.id, refreshToken);

  return { accessToken, refreshToken, user };
};

// // 🔁 REFRESH ACCESS TOKEN
// const refreshAccessToken = async (refreshToken) => {
//   const stored = await repo.findRefreshToken(refreshToken);
//   if (!stored) throw new Error("Invalid refresh token");

//   // 🔥 ROTATION: delete used token
//   await repo.deleteRefreshToken(refreshToken);

//   const user = await repo.findUserById(stored.user_id);
//   if (!user) throw new Error("User not found");

//   const newAccessToken = jwt.sign(
//     {
//       user: {
//         id: user.id,
//         username: user.username,
//         email: user.email,
//         user_type: user.user_type,
//       },
//     },
//     process.env.ACCESS_TOKEN_SECRET,
//     // { expiresIn: "1d" }
//     { expiresIn: "50m" } // ⏱ TEMP: for refresh-token testing
//   );

//   // 🔁 Issue new refresh token
//   const newRefreshToken = generateRefreshToken();
//   await repo.saveRefreshToken(user.id, newRefreshToken);

//   return {
//     accessToken: newAccessToken,
//     refreshToken: newRefreshToken,
//   };
// };
const refreshAccessToken = async (refreshToken) => {
  const stored = await repo.findRefreshToken(refreshToken);

  if (!stored) {
    const err = new Error("SESSION_EXPIRED");
    err.statusCode = 401;
    throw err;
  }

  // 🔁 ROTATION: delete old refresh token
  await repo.deleteRefreshToken(refreshToken);

  const user = await repo.findUserById(stored.user_id);
  if (!user) {
    const err = new Error("SESSION_EXPIRED");
    err.statusCode = 401;
    throw err;
  }

  const newAccessToken = jwt.sign(
    {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        user_type: user.user_type,
      },
    },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: "50m" }
  );

  const newRefreshToken = generateRefreshToken();
  await repo.saveRefreshToken(user.id, newRefreshToken);

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  };
};
// ---------------- LOGOUT ----------------
const logout = async (refreshToken) => {
  if (!refreshToken) return;

  await repo.deleteRefreshToken(refreshToken);
};

// ---------------- FORGOT PASSWORD ----------------

// Step 1: Send reset OTP to user's email
const forgotPassword = async ({ username }) => {
  if (!username) throw new Error("Username is required");

  const user = await repo.findUserByUsername(username);
  if (!user) throw new Error("User not found");
  if (!user.email) throw new Error("No email associated with this account");

  const otp = generateOTP();
  await repo.saveOTP(user.id, otp, "email");

  // Try to send email, but don't fail if email service is down
  try {
    await sendEmail(user.email, otp);
    console.log(`✅ Reset OTP sent to ${user.email}`);
  } catch (emailErr) {
    console.log(`⚠️  Email sending failed, but OTP is saved.`);
    console.log(`🔑 RESET OTP for "${username}": ${otp}`);
  }

  // Return a temp token so the user can verify OTP and reset password
  const tempToken = jwt.sign({ id: user.id, purpose: "reset" }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "10m",
  });

  return {
    message: "OTP sent to your registered email",
    tempToken,
  };
};

// Step 2: Verify OTP for password reset
const verifyResetOTP = async ({ userId, otp }) => {
  const found = await repo.findValidOTP(userId, otp);
  if (!found) throw new Error("Invalid or expired OTP");

  await repo.deleteOTP(userId);

  // Issue a short-lived token specifically for resetting password
  const resetToken = jwt.sign({ id: userId, purpose: "reset_confirmed" }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "5m",
  });

  return {
    message: "OTP verified. You can now reset your password.",
    resetToken,
  };
};

// Step 3: Reset the password
const resetPassword = async ({ userId, newPassword }) => {
  if (!newPassword || newPassword.length < 8) {
    throw new Error("Password must be at least 8 characters");
  }

  const passwordHash = await bcrypt.hash(newPassword, 10);
  const updated = await repo.updatePassword(userId, passwordHash);

  if (!updated) throw new Error("User not found");

  // Invalidate all existing refresh tokens for security
  await repo.deleteRefreshTokensByUser(userId);

  return { message: "Password reset successfully" };
};




module.exports = {
  register,
  login,
  loginAdmin,
  updateUser,
  getUserById,
  deleteSelf,
  deleteUserByAdmin,
  getAllUsers,
  loginOwner,
  sendOTP,
  verifyOTP,
  refreshAccessToken,
  logout,
  forgotPassword,
  verifyResetOTP,
  resetPassword
};
