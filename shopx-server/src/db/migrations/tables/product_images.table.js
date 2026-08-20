module.exports = async (client) => {
  try {
    console.log("Checking if product_images table exists...");

    const result = await client.query(`
      SELECT to_regclass('public.product_images') AS table_name;
    `);

    const tableExists = result.rows[0].table_name !== null;

    if (tableExists) {
      console.log("✔️ 'product_images' table already exists.");
      return;
    }

    console.log("⏳ Creating 'product_images' table...");

    await client.query(`
      CREATE TABLE product_images (
        id SERIAL PRIMARY KEY,
        product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
        image_path TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log("✅ 'product_images' table created successfully!");

  } catch (err) {
    console.error("❌ Failed to create 'product_images' table:", err.message);
  }
};
