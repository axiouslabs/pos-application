module.exports = async (client) => {
  try {
    // 1️⃣ Check if table already exists
    const check = await client.query(`
      SELECT to_regclass('public.roles') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "roles" table already exists.');
      return;
    }

    // 2️⃣ Create table
    await client.query(`
      CREATE TABLE roles (
        id SERIAL PRIMARY KEY,
        role_name VARCHAR(50) UNIQUE NOT NULL
      );
    `);

    // 3️⃣ Insert default roles
    await client.query(`
      INSERT INTO roles (role_name)
      VALUES ('admin'), ('sales'), ('manager')
      ON CONFLICT DO NOTHING;
    `);

    console.log('✅ "roles" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "roles" table:', err.message);
    throw err;
  }
};

/*Why do we need a roles table?
✔ Centralized management

Instead of hardcoding "admin" or "sales" everywhere, you use role IDs.

✔ Future expansion

If client says “Add accountant role”, you just insert a new row into roles.

✔ Cleaner backend code

You can add middleware like:

checkRole("manager")
checkRole("accountant")
checkRole("sales")

✔ Makes your app industry-level

This is how large ERP systems handle users. */
