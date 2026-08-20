const  pool  = require("../../config/db");
const createUsersTable = require("./tables/users.tables");
const createProductTable = require("./tables/products.table");
const createStockTable = require("./tables/stock.tables");
const createCustomerTable = require("./tables/customers.table");
const createSalesTable = require("./tables/sales.table");
const createSaleItemsTable = require("./tables/sale_items.table");
const createPaymentsTable = require("./tables/payments.table");
const createReceiptsTable = require("./tables/reciepts.table");
const createEmployeeAttendanceTable = require("./tables/employee_attendance.table");
const createPriceHistoryTable = require("./tables/price_history.table");
const createRolesTable = require("./tables/roles.table");
const createStockMovementsTable = require("./tables/stockMovements.table");
const createSaleBalanceTable = require("./tables/saleBalance.table");
const createOwnerOTPsTable = require("./tables/owner_otps.table");
const createProductImagesTable = require("./tables/product_images.table");






const createTables = async () => {
  const client = await pool.connect();

  try {
    console.log("🚀 Running migrations...");

    await createUsersTable(client);
   await createProductTable(client);
    await createStockTable(client);
    await createCustomerTable(client);
    await createSalesTable(client);
    await createSaleItemsTable(client);
    await createPaymentsTable(client);  
    await createReceiptsTable(client);
    await createEmployeeAttendanceTable(client);
    await createPriceHistoryTable(client);
    await createRolesTable(client);
    await createStockMovementsTable(client);
    await createSaleBalanceTable(client);
    await createOwnerOTPsTable(client);
    await createProductImagesTable(client);







    console.log("✅ All tables created successfully!");
  } catch (err) {
    console.error("❌ Migration failed:", err);
    process.exit(1);
  } finally {
    client.release();
  }
};

// We export createTables so migrate.js or server.js can use it.
module.exports = createTables;
