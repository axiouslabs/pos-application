module.exports = async (client) => {
  try {
    const result = await client.query(`
         SELECT to_regclass('public.users') AS table_name;
   `);

    const tableExists = result.rows[0].table_name !== null;

    if (tableExists) {
      console.log('ℹ️ "users" table already exists.');
    } else {
      // 2️⃣ If table does NOT exist → create it
      await client.query(`
        CREATE TABLE "users" (
          id SERIAL PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          email VARCHAR(150) UNIQUE NOT NULL,
          password VARCHAR(255) NOT NULL,
          phone VARCHAR(10) NOT NULL,
          user_type VARCHAR(10) CHECK (user_type IN ('user', 'admin')) DEFAULT 'user' NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      `);
      console.log('✅ "users" table has been created.');
    }
  } catch (err) {
    console.error('❌ Failed to create "users" table:', err.message);
    throw err;
  }
};
