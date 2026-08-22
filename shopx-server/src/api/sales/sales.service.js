const db = require("../../config/db");
const repo = require("./sales.repositary");

// For stock deduction
// ✔ USE STOCK *SERVICE* — not repository!
const stockService = require("../stock/stock.service");

// For payments
const paymentsRepo = require("../payments/payments.repository");

exports.createSale = async (data) => {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    // 1️⃣ VALIDATE ITEMS
    if (!data.items || data.items.length === 0) {
      throw new Error("At least one item is required");
    }
    if (!data.customer_id) {
      throw new Error("Customer is required");
    }

    // 2️⃣ CALCULATE SUBTOTAL

    const VAT_PERCENTAGE = 15;

    // 1️⃣ GROSS SUBTOTAL (NO ITEM DISCOUNT)
    let gross_subtotal = 0;
    data.items.forEach((i) => {
      gross_subtotal += i.quantity * i.unit_price;
    });

    // 2️⃣ SALE-LEVEL DISCOUNT
    const discount_amount = Number(data.discount_amount || 0);

    if (discount_amount < 0) {
      throw new Error("Discount cannot be negative");
    }

    if (discount_amount > gross_subtotal) {
      throw new Error("Discount cannot exceed subtotal");
    }

    // // 3️⃣ TAXABLE AMOUNT
    // const taxable_amount = gross_subtotal - discount_amount;

    // // 4️⃣ VAT
    // const vat_amount = taxable_amount * (VAT_PERCENTAGE / 100);

    // // 5️⃣ FINAL TOTAL
    // const total_amount = taxable_amount + vat_amount;

    // 3️⃣ VAT — CALCULATED ON GROSS SUBTOTAL (DISCOUNT DOES NOT AFFECT VAT)
    const vat_amount = +(gross_subtotal * (VAT_PERCENTAGE / 100)).toFixed(2);

    // 4️⃣ FINAL TOTAL = SUBTOTAL + VAT - DISCOUNT
    const total_amount = +(
      gross_subtotal +
      vat_amount -
      discount_amount
    ).toFixed(2);

    // Safety check
    if (total_amount < 0) {
      throw new Error("Total amount cannot be negative");
    }

    // 3️⃣ CREATE MAIN SALE
  const sale = await repo.createSale(client, {
  salesperson_id: data.salesperson_id,
  customer_id: data.customer_id,
  subtotal_amount: gross_subtotal,
  discount_amount,
  vat_percentage: VAT_PERCENTAGE,
  vat_amount,
  total_amount,
  payment_method: data.payment_method,
  payment_status: data.payment_status,
});


    let isBackorder = false;

    // 5️⃣ INSERT SALE ITEMS
    for (const item of data.items) {
      const stock = await stockService.getStock(item.product_id);
      const availableQty = stock?.quantity || 0;

      const fulfillQty = Math.min(availableQty, item.quantity);
      const pendingQty = item.quantity - fulfillQty;

      // ✅ FETCH PRODUCT NAMES (English + Arabic)
      const productRes = await client.query(
        `SELECT name, name_ar FROM products WHERE id = $1`,
        [item.product_id]
      );

      const product = productRes.rows[0];

      await client.query(
        `INSERT INTO sale_items 
     (
       sale_id,
       product_id,
       product_name,
       product_name_ar,
       quantity,
       fulfilled_quantity,
       unit_price,
       discount,
       total_price
     )
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [
          sale.id,
          item.product_id,
          product.name,
          product.name_ar,
          item.quantity,
          fulfillQty,
          item.unit_price,
          item.discount || 0,
          item.quantity * (item.unit_price - (item.discount || 0)),
        ]
      );

      // Deduct FULL sold quantity (allow negative stock)
      await stockService.adjustStock(item.product_id, -item.quantity, "sale");

      if (pendingQty > 0) {
        isBackorder = true;
      }
    }

    // 6️⃣ UPDATE SALE STATUS (FINAL & ONLY PLACE)
    const saleStatus = isBackorder ? "backorder" : "completed";
    await repo.updateSaleStatus(client, sale.id, saleStatus);

    // 7️⃣ CREATE ONE FULL PAYMENT (ALWAYS PAID – CLIENT RULE)
   // 7️⃣ CREATE PAYMENT (PAID or PENDING)
const paymentStatus = data.payment_status || "paid";

const payment = await paymentsRepo.createPayment(client, {
  saleId: sale.id,
  customerId: data.customer_id,
  amount: total_amount,
  method: data.payment_method || "cash",
  status: paymentStatus,
});

// 🔁 Sync sale payment status
await client.query(
  `UPDATE sales SET payment_status = $1 WHERE id = $2`,
  [paymentStatus, sale.id]
);

    await client.query("COMMIT");

    return {
      sale,
      payment: payment.rows[0],
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

exports.voidSale = async (saleId, user) => {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    // 1️⃣ Fetch sale
    const sale = await repo.getSaleById(client, saleId);

    if (!sale) throw new Error("Sale not found");

    // Check if already voided (either sale_status OR payment_status indicates void)
    const isAlreadyVoided =
      sale.sale_status === "voided" ||
      sale.sale_status === "void" ||
      sale.sale_status === "canceled" ||
      sale.payment_status === "voided" ||
      sale.payment_status === "void" ||
      sale.payment_status === "canceled";

    if (isAlreadyVoided) {
      // Idempotent: ensure both statuses are consistent for old records
      await client.query(
        `UPDATE sales SET sale_status = 'voided', payment_status = 'voided' WHERE id = $1`,
        [saleId]
      );
      await client.query("COMMIT");
      return { saleId, status: "voided", alreadyVoided: true };
    }

    // 2️⃣ Reverse stock using sale_items
    const items = await repo.getSaleItems(client, saleId);

    for (const item of items) {
      await stockService.adjustStock(
        item.product_id,
        item.quantity,   // ADD BACK
        "sale_void"
      );
    }

    // 3️⃣ Update sale_status AND payment_status — both inside the transaction
    await client.query(
      `UPDATE sales SET sale_status = 'voided', payment_status = 'voided' WHERE id = $1`,
      [saleId]
    );

    // 4️⃣ Reverse ALL non-reversed payments (paid AND pending)
    await client.query(
      `UPDATE payments SET status = 'reversed'
       WHERE sale_id = $1 AND status IN ('paid', 'pending')`,
      [saleId]
    );

    await client.query("COMMIT");

    return { saleId, status: "voided" };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};


exports.getFullInvoice = async (id) => {
  return await repo.getFullInvoice(id);
};
exports.getAllSales = async (limit = 500) => {
  return await repo.getAllSales(limit);
};

exports.getSalesBySalesperson = async (salespersonId) => {
  return await repo.getSalesBySalesperson(salespersonId, 100);
};

exports.getSalesByCustomer = async (customerId) => {
  return await repo.getSalesByCustomer(customerId);
};

