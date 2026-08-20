const db = require("../../config/db");

// --- SELECT ---
const findUserByEmail = async (email) => {
  const r = await db.query("SELECT * FROM users WHERE email = $1", [email]);
  return r.rows[0] || null;
};

const findUserByUsername = async (username) => {
  const r = await db.query("SELECT * FROM users WHERE username = $1", [
    username,
  ]);
  return r.rows[0] || null;
};

const findUserById = async (id) => {
  const r = await db.query(
    "SELECT id, username, email, user_type, phone FROM users WHERE id = $1", // ✅ ADDED phone
    [id]
  );
  return r.rows[0] || null;
};

const getAllUsers = async () => {
  const r = await db.query(
    "SELECT id, username, email, user_type, phone FROM users ORDER BY id ASC" // ✅ ADDED phone
  );
  return r.rows;
};

// --- INSERT ---
const createUser = async ({ username, email, passwordHash, user_type, phone }) => {
  const r = await db.query(
    "INSERT INTO users (username, email, password, user_type, phone) VALUES ($1,$2,$3,$4,$5) RETURNING *", // ✅ ADDED phone column
    [username, email, passwordHash, user_type, phone] // ✅ ADDED phone parameter
  );
  return r.rows[0];
};

// --- UPDATE ---
const updateUser = async (id, username, email, phone) => {
  const r = await db.query(
    "UPDATE users SET username = COALESCE($1, username), email = COALESCE($2, email), phone = COALESCE($3, phone) WHERE id = $4 RETURNING id, username, email, phone", // ✅ ADDED phone
    [username, email, phone, id] // ✅ ADDED phone parameter
  );
  return r.rows[0];
};

// --- DELETE ---
const deleteUserById = async (id) => {
  const r = await db.query("DELETE FROM users WHERE id = $1 RETURNING *", [id]);
  return r.rows[0] || null;
};

// --- OTP SYSTEM ---

// Save or update OTP for a user
const saveOTP = async (userId, otp, method) => {
  await db.query(
    `INSERT INTO  owner_otps (user_id, otp, method, expires_at)
     VALUES ($1, $2, $3, NOW() + INTERVAL '5 minutes')
     ON CONFLICT (user_id)
     DO UPDATE SET otp = $2, method = $3, expires_at = NOW() + INTERVAL '5 minutes'`,
    [userId, otp, method]
  );
};

// Find valid (not expired) OTP
const findValidOTP = async (userId, otp) => {
  const r = await db.query(
    `SELECT * FROM owner_otps
     WHERE user_id = $1 AND otp = $2 AND expires_at > NOW()`,
    [userId, otp]
  );
  return r.rows[0] || null;
};

// Delete OTP after successful verification
const deleteOTP = async (userId) => {
  await db.query(`DELETE FROM owner_otps WHERE user_id = $1`, [userId]);
};

const countAdmins = async () => {
  const query = `SELECT COUNT(*) FROM users WHERE user_type = 'admin'`;
  const result = await db.query(query);
  return parseInt(result.rows[0].count);
};


// ================= REFRESH TOKEN SYSTEM =================

// Save refresh token for a user
const saveRefreshToken = async (userId, token) => {
  await db.query(
    `INSERT INTO refresh_tokens (user_id, token, expires_at)
     VALUES ($1, $2, NOW() + INTERVAL '90 days')`,
    [userId, token]
  );
};

// Find valid refresh token
const findRefreshToken = async (token) => {
  const r = await db.query(
    `SELECT * FROM refresh_tokens
     WHERE token = $1 AND expires_at > NOW()`,
    [token]
  );
  return r.rows[0] || null;
};

// Delete refresh token (logout / rotation)
const deleteRefreshToken = async (token) => {
  await db.query(
    `DELETE FROM refresh_tokens WHERE token = $1`,
    [token]
  );
};

// ❌ Delete ALL refresh tokens for a user (login / OTP)
const deleteRefreshTokensByUser = async (userId) => {
  await db.query(
    `DELETE FROM refresh_tokens WHERE user_id = $1`,
    [userId]
  );
};

// ================= PASSWORD RESET =================

// Update user password
const updatePassword = async (userId, passwordHash) => {
  const r = await db.query(
    `UPDATE users SET password = $1 WHERE id = $2 RETURNING id, username, email`,
    [passwordHash, userId]
  );
  return r.rows[0] || null;
};




module.exports = {
  findUserByEmail,
  findUserByUsername,
  findUserById,
  getAllUsers,
  createUser,
  updateUser,
  deleteUserById,
  saveOTP,
  findValidOTP,
  deleteOTP,
   countAdmins,
   saveRefreshToken,
  findRefreshToken,
  deleteRefreshToken,
   deleteRefreshTokensByUser,
   updatePassword
};
