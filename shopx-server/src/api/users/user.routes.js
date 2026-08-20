const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const validateToken = require("../../middleware/validateTokenHandler");
const checkAdmin = require("../../middleware/checkAdmin");

// ⭐ GET ALL SALESPERSONS
router.get("/salespersons", validateToken, checkAdmin, async (req, res) => {
  const result = await db.query(
    `SELECT id, username, email, phone 
     FROM users 
     WHERE user_type = 'user'
     ORDER BY id ASC`
  );
  res.json(result.rows);
});

// ⭐ GET ONE SALESPERSON
router.get("/salespersons/:id", validateToken, checkAdmin, async (req, res) => {
  const result = await db.query(
    `SELECT id, username, email, phone 
     FROM users 
     WHERE id = $1 AND user_type = 'user'`,
    [req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ message: "Salesperson not found" });
  }

  res.json(result.rows[0]);
});

// ⭐ UPDATE SALESPERSON
router.put("/salespersons/:id", validateToken, checkAdmin, async (req, res) => {
  const { username, email, phone } = req.body;

  const result = await db.query(
    `UPDATE users SET 
       username = COALESCE($1, username),
       email = COALESCE($2, email),
       phone = COALESCE($3, phone)
     WHERE id = $4 AND user_type = 'user'
     RETURNING id, username, email, phone`,
    [username, email, phone, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ message: "Salesperson not found" });
  }

  res.json({ message: "Salesperson updated", user: result.rows[0] });
});

// ⭐ DELETE SALESPERSON
router.delete("/salespersons/:id", validateToken, checkAdmin, async (req, res) => {
  const result = await db.query(
    `DELETE FROM users 
     WHERE id = $1 AND user_type = 'user'
     RETURNING *`,
    [req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ message: "Salesperson not found" });
  }

  res.json({ message: "Salesperson deleted" });
});

module.exports = router;
