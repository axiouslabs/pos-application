const db = require("../../config/db");
const repo = require("./stock.repository");

async function ensureStockRow(productId) {
  const existing = await repo.getStockByProduct(productId);
  if (!existing) {
    // create initial row with 0
    await repo.createStockRow(productId, 0);
    return { product_id: productId, quantity: 0 };
  }
  return existing;
}

/**
 * Adjust stock: qtyChange can be +ve (add) or -ve (remove)
 * Returns the updated stock row.
 */

async function adjustStock(productId, qtyChange, reason = "adjustment") {
  // 1️⃣ Ensure stock row exists
  await ensureStockRow(productId);

  // 2️⃣ Increase stock first (admin add)
  const updatedStock = await repo.updateStockQuantity(productId, qtyChange);

  // 3️⃣ Record stock movement
  await repo.insertStockMovement(productId, qtyChange, reason);

  // 4️⃣ ONLY when stock is ADDED → try to fulfill backorders
  if (qtyChange > 0) {
    await fulfillBackorders(productId);
  }

  return updatedStock;
}

async function fulfillBackorders(productId) {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    const stock = await repo.getStockByProduct(productId);
    let availableQty = stock.quantity;

    if (availableQty <= 0) {
      await client.query("COMMIT");
      return;
    }

    const result = await client.query(
      `
      SELECT si.*, s.id AS sale_id
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE si.product_id = $1
        AND si.quantity > si.fulfilled_quantity
        AND s.sale_status = 'backorder'
      ORDER BY s.sale_date ASC
      `,
      [productId]
    );

    for (const row of result.rows) {
      if (availableQty <= 0) break;

      const remaining = row.quantity - row.fulfilled_quantity;
      const fulfillQty = Math.min(remaining, availableQty);

      await client.query(
        `
        UPDATE sale_items
        SET fulfilled_quantity = fulfilled_quantity + $1
        WHERE id = $2
        `,
        [fulfillQty, row.id]
      );

      // deduct stock immediately
      await repo.updateStockQuantity(productId, -fulfillQty);

      availableQty -= fulfillQty;

      const check = await client.query(
        `
        SELECT COUNT(*) 
        FROM sale_items
        WHERE sale_id = $1
          AND quantity > fulfilled_quantity
        `,
        [row.sale_id]
      );

      if (Number(check.rows[0].count) === 0) {
        await client.query(
          `UPDATE sales SET sale_status = 'completed' WHERE id = $1`,
          [row.sale_id]
        );
      }
    }

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function getStock(productId) {
  const stock = await repo.getStockByProduct(productId);
  return stock;
}

async function getAllStock() {
  const rows = await repo.getAllStock();
  return rows;
}

async function getStockMovements(productId, limit = 100) {
  return await repo.getStockMovements(productId, limit);
}

module.exports = {
  adjustStock,
  getStock,
  getAllStock,
  getStockMovements,
  ensureStockRow,
};
