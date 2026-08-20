const db = require("../../config/db");

exports.createCustomer = async ({
  name,
  phone,
  address,
  tin,
  area,
  salesperson_id,
}) => {
  const result = await db.query(
    `INSERT INTO customers (name, phone, address, tin, area, salesperson_id)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      name,
      phone || null,
      address,
      tin || null,
      area || null,
      salesperson_id,
    ]
  );

  return result.rows[0];
};

exports.getAllCustomers = async () => {
  const result = await db.query(`SELECT * FROM customers ORDER BY id ASC`);
  return result.rows;
};

exports.getCustomersBySalesperson = async (salespersonId) => {
  const result = await db.query(
    `SELECT * FROM customers 
     WHERE salesperson_id = $1 
     ORDER BY id ASC`,
    [salespersonId]
  );
  return result.rows;
};


exports.getCustomerById = async (id) => {
  const result = await db.query(`SELECT * FROM customers WHERE id = $1`, [id]);
  return result.rows[0];
};
exports.updateCustomer = async (
  id,
  { name, phone, address, tin, area }
) => {
  const result = await db.query(
    `UPDATE customers
     SET name = COALESCE($1, name),
         phone = COALESCE($2, phone),
         address = COALESCE($3, address),
         tin = COALESCE($4, tin),
         area = COALESCE($5, area)
     WHERE id = $6
     RETURNING *`,
    [name, phone, address, tin, area, id]
  );

  return result.rows[0];
};


exports.deleteCustomer = async (id) => {
  const result = await db.query(
    `DELETE FROM customers WHERE id = $1 RETURNING *`,
    [id]
  );
  return result.rows[0];
};
