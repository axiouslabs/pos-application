//Purpose: Small, clean.
//  Takes request → calls service → returns response.
 
const asyncHandler = require("express-async-handler");
const service = require("./products.service");

// GET /products
exports.getAllProducts = asyncHandler(async(req,res)=>{
    const products = await service.getAllProducts();
    res.json(products);
});


// GET /products/:id
exports.getProductById = asyncHandler(async(req,res)=>{
    const product =await service.getProductById(req.params.id);
    res.json(product);
});



// POST /products
// Create product (NO images)
exports.createProduct = asyncHandler(async (req, res) => {
  const product = await service.createProduct(req.body);

  res.status(201).json({
    message: "Product created",
    id: product.id,
    product
  });
});

// Upload images separately
exports.uploadImages = asyncHandler(async (req, res) => {
  const productId = req.params.id;

  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ message: "No images uploaded" });
  }

  await service.saveProductImages(productId, req.files);

  res.json({ message: "Images uploaded successfully" });
});



// PUT /products/:id
exports.updateProduct = asyncHandler(async(req,res)=>{
    const updated = await service.updateProduct(req.params.id,req.body);
    res.json(updated);
});

// DELETE /products/:id
exports.deleteProduct = asyncHandler(async(req,res)=>{
    await service.deleteProduct(req.params.id);
    res.json({message: "Product deleted"} );
});



// POST /products/:id/adjust-stock
exports.adjustStock = asyncHandler(async (req, res) => {
  const { quantity, reason } = req.body;

  const stock = await service.adjustStock({
    productId: req.params.id,
    quantityChange: quantity,
    reason: reason || "manual",
  });

  res.json(stock);
});
