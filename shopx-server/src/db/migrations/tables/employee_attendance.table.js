module.exports = async (client) => {
  try {
    // 1️⃣ Check if table already exists
    const check = await client.query(`
      SELECT to_regclass('public.employee_attendance') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "employee_attendance" table already exists.');
      return;
    }

    // 2️⃣ Create table
    await client.query(`
      CREATE TABLE employee_attendance (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        check_in TIMESTAMP,
        check_out TIMESTAMP,
        status VARCHAR(20) DEFAULT 'present'  -- present, absent, leave
      );
    `);

    console.log('✅ "employee_attendance" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "employee_attendance" table:', err.message);
    throw err;
  }
};

/*✔ Track attendance per salesman

Admin knows which salesman was active on which day.

✔ Can calculate monthly reports

total days worked

leaves

productivity per day

attendance vs sales comparison

✔ Can implement check-in/check-out

Salesperson opens app → Check-in
End of day → Check-out

✔ Supports future payroll

If needed later, salary calculation becomes easy. */