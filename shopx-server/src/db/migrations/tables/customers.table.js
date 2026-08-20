module.exports = async (client) => {
  try {
    // 1️⃣ Check if table exists
    const check = await client.query(`
      SELECT to_regclass('public.customers') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "customers" table already exists.');
      return;
    }

    // 2️⃣ Create table
    await client.query(`
     CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,

  phone VARCHAR(20),          -- optional
  tin VARCHAR(50),            -- optional
  address TEXT,

  area VARCHAR(100),          -- ✅ NEW
  salesperson_id INTEGER,     -- ✅ NEW

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

    `);

    console.log('✅ "customers" table created successfully.');

  } catch (err) {
    console.error('❌ Failed to create "customers" table:', err.message);
    throw err;
  }
};
/*This table stores information about every shop the salesperson sells to.
✔️ Salesman → Selects Customer → Adds products → Prints bill
✔️ Admin → Checks which customers bought which items
✔️ Filtering per customer for reports

This table is very important for:

Daily sales report

Customer purchase history

Generating receipts

Tracking outstanding payments (if any)
*/ 