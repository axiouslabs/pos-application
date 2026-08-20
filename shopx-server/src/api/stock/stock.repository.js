const db = require("../../config/db");

// Returns one row or null
exports.getStockByProduct = async (productId) => {
  const r = await db.query(`SELECT * FROM stock WHERE product_id = $1`, [productId]);
  return r.rows[0] || null;
};

exports.createStockRow = async (productId, quantity = 0) => {
  const r = await db.query(
    `INSERT INTO stock (product_id, quantity) VALUES ($1, $2) RETURNING *`,
    [productId, quantity]
  );
  return r.rows[0];
};

exports.updateStockQuantity = async (productId, qtyChange) => {
  // atomic update and return
  const r = await db.query(
    `UPDATE stock
     SET quantity = quantity + $1,
         last_updated = CURRENT_TIMESTAMP
     WHERE product_id = $2
     RETURNING *`,
    [qtyChange, productId]
  );
  return r.rows[0];
};

exports.insertStockMovement = async (productId, change, reason) => {
  return await db.query(
    `INSERT INTO stock_movements (product_id, change, reason)
     VALUES ($1, $2, $3) RETURNING *`,
    [productId, change, reason]
  );
};

exports.getAllStock = async () => {
  const r = await db.query(
    `SELECT s.*, p.name AS product_name
     FROM stock s
     JOIN products p ON p.id = s.product_id
     ORDER BY p.name ASC`
  );
  return r.rows;
};

exports.getStockMovements = async (productId, limit = 100) => {
  const r = await db.query(
    `SELECT sm.*, p.name as product_name
     FROM stock_movements sm
     JOIN products p ON p.id = sm.product_id
     WHERE sm.product_id = $1
     ORDER BY sm.created_at DESC
     LIMIT $2`,
    [productId, limit]
  );
  return r.rows;
};
