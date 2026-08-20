//Only SQL. No business rules.

const db = require("../../config/db");
exports.getAllProducts = async () => {
  return await db.query(`
    SELECT * 
    FROM products
    ORDER BY id ASC
  `);
};

exports.getProductById = async (id) => {
  return await db.query(
    `
    SELECT * 
    FROM products
    WHERE id = $1
  `,
    [id]
  );
};

exports.createProduct = async ({
  name,
  name_ar,
  price,
  category,
  code,
  vat,
}) => {
  return await db.query(
    `
    INSERT INTO products (name, name_ar, price, category, code, vat)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *
  `,
    [name, name_ar, price, category, code, vat]
  );
};

exports.updateProduct = async (
  id,
  { name, name_ar, price, category, code, vat }
) => {
  return await db.query(
    `
    UPDATE products 
    SET 
      name = COALESCE($1, name),
      name_ar = COALESCE($2, name_ar),
      price = COALESCE($3, price),
      category = COALESCE($4, category),
      code = COALESCE($5, code),
      vat = COALESCE($6, vat)
    WHERE id = $7
    RETURNING *
  `,
    [name, name_ar, price, category, code, vat, id]
  );
};

exports.deleteProduct = async (id) => {
  return await db.query(
    `
      DELETE FROM products WHERE id = $1 RETURNING*`,
    [id]
  );
};

// STOCK MANAGEMENT SECTION
exports.getStocksByProduct = async (productId) => {
  return await db.query(
    `
        SELECT * FROM stock WHERE product_id = $1`,
    [productId]
  );
};

// ADJUST STOCK QUANTITY
// This function updates stock quantity and records why it changed
exports.adjustStock = async ({ productId, quantityChange, reason }) => {
  // 1️⃣ Create a stock row if it doesn't exist
  await db.query(
    `INSERT INTO stock (product_id, quantity)
         VALUES ($1, 0)
         ON CONFLICT (product_id) DO NOTHING`,
    [productId]
  );

  // 2️⃣ Update stock quantity
  const stock = await db.query(
    `UPDATE stock
         SET quantity = quantity + $1
         WHERE product_id = $2
         RETURNING *`,
    [quantityChange, productId]
  );

  // 3️⃣ Log stock movement
  await db.query(
    `INSERT INTO stock_movements (product_id, change, reason)
         VALUES ($1, $2, $3)`,
    [productId, quantityChange, reason]
  );

  return stock;
};

// RECORD PRICE CHANGES
// This function saves a history record whenever a product's price changes
exports.addPriceHistory = async (productId, oldPrice, newPrice) => {
  return await db.query(
    `INSERT INTO price_history (product_id,old_price,new_price)
        VALUES($1,$2,$3)`,
    [productId, oldPrice, newPrice]
  );
};

// Save product image
exports.addProductImage = async (productId, image_path) => {
  return await db.query(
    `
      INSERT INTO product_images (product_id, image_path )
      VALUES($1,$2)
      RETURNING *
    `,
    [productId, image_path]
  );
};

// Get all images for a product
exports.getImagesByProduct = async (productId) => {
  return await db.query(
    `
      SELECT image_path 
      FROM product_images
      WHERE product_id = $1
    `,
    [productId]
  );
};
