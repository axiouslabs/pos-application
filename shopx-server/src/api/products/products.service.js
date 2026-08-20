// All business logic.

const repo = require("./products.repository");

// This function gets all products from the database
exports.getAllProducts = async () => {
  const result = await repo.getAllProducts();
  const products = result.rows;

  for (const product of products) {
    const imgRes = await repo.getImagesByProduct(product.id);
    product.images = imgRes.rows.map((row) => row.image_path);

    // ⭐ NEW: attach real stock
    const stockRes = await repo.getStocksByProduct(product.id);
    product.quantity = stockRes.rows[0]?.quantity ?? 0;
  }

  return products;
};

exports.getProductById = async (id) => {
  const result = await repo.getProductById(id);
  if (result.rows.length === 0) throw new Error("Product not found");

  const product = result.rows[0];

  // Attach images
  const imgRes = await repo.getImagesByProduct(id);
  product.images = imgRes.rows.map((r) => r.image_path);

  // ⭐ NEW: get real stock
  const stockRes = await repo.getStocksByProduct(id);
  const realStock = stockRes.rows[0]?.quantity ?? 0;

  // ⭐ OVERRIDE quantity with real stock
  product.quantity = realStock;

  return product;
};

// CREATE NEW PRODUCT
// This function creates a product AND sets up its initial stock
exports.createProduct = async (data) => {
  const { quantity = 0 } = data;

  // create product WITHOUT quantity
  const createRes = await repo.createProduct(data);
  const product = createRes.rows[0];

  // create initial stock
  if (quantity !== 0) {
    await repo.adjustStock({
      productId: product.id,
      quantityChange: Number(quantity),
      reason: "initial-stock",
    });
  }

  return product;
};


exports.updateProduct = async (id, data) => {
  const oldProductRes = await repo.getProductById(id);
  if (oldProductRes.rows.length === 0) {
    throw new Error("Product not found");
  }

  const oldProduct = oldProductRes.rows[0];

  // 3️⃣ Update other product fields
  const updateRes = await repo.updateProduct(id, data);
  return updateRes.rows[0];
};

exports.deleteProduct = async (id) => {
  const result = await repo.deleteProduct(id);

  if (result.rows.length === 0) throw new Error("Product not found");

  return result.rows[0];
};

exports.adjustStock = async ({ productId, quantityChange, reason }) => {
  const stockRes = await repo.adjustStock({
    productId,
    quantityChange,
    reason,
  });

  return stockRes.rows[0];
};

// GET STOCK INFORMATION
// This function gets current stock levels for a product
exports.getStockWithHistory = async (productId) => {
  const stock = await repo.getStocksByProduct(productId);
  return stock.rows[0];
};

exports.saveProductImages = async (productId, files) => {
  for (const file of files) {
    const imagePath = `/uploads/products/${file.filename}`;
    await repo.addProductImage(productId, imagePath);
  }
};
