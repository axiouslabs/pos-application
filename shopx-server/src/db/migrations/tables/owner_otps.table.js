// src/db/migrations/tables/owner_otps.table.js
module.exports = async (client) => {
  try {
    // Check if table already exists
    const check = await client.query(`
      SELECT to_regclass('public.owner_otps') AS table_name;
    `);

    if (check.rows[0].table_name) {
      console.log('ℹ️ "owner_otps" table already exists.');
      return;
    }

    // Create the OTP table
    await client.query(`
      CREATE TABLE owner_otps (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        otp VARCHAR(10) NOT NULL,                       -- The 4-digit code
        method VARCHAR(20) NOT NULL,                    -- 'sms' or 'email'
        expires_at TIMESTAMP NOT NULL,                  -- When OTP expires (5 minutes)
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When OTP was created
      );
    `);

    console.log('✅ "owner_otps" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "owner_otps" table:', err.message);
    throw err;
  }
};