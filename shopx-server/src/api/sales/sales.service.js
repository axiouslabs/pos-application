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
        [item.product_id],
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
        ],
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

    // 7️⃣ HANDLE PAYMENT CORRECTLY (PRODUCTION LOGIC)

    const paymentStatus = data.payment_status === "paid" ? "paid" : "pending";

    // 🔁 Always update sale payment status
    await client.query(`UPDATE sales SET payment_status = $1 WHERE id = $2`, [
      paymentStatus,
      sale.id,
    ]);

    // ✅ ONLY create payment record if PAID
    let payment = null;

    if (paymentStatus === "paid") {
      const paymentResult = await paymentsRepo.createPayment(client, {
        saleId: sale.id,
        customerId: data.customer_id,
        amount: total_amount,
        method: data.payment_method || "cash",
        status: "paid",
      });

      payment = paymentResult.rows[0];
    }

    await client.query("COMMIT");

    return {
      sale,
      payment,
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

    // 🔒 Lock row to prevent double void (CRITICAL)
    const saleRes = await client.query(
      `SELECT * FROM sales WHERE id = $1 FOR UPDATE`,
      [saleId],
    );

    const sale = saleRes.rows[0];

    if (!sale) {
      throw new Error("Sale not found");
    }

    // 🚫 HARD STOP: already voided
    if (sale.sale_status === "voided") {
      throw new Error("Sale already cancelled");
    }

    // 🔁 Reverse stock ONCE
    const items = await repo.getSaleItems(client, saleId);
    for (const item of items) {
      await stockService.adjustStock(
        item.product_id,
        item.quantity,
        "sale_void",
      );
    }

    // 🔁 Reverse payment ONLY if PAID
    if (sale.payment_status === "paid") {
      await paymentsRepo.reversePaymentBySaleId(client, saleId);
    }

    // ✅ Mark sale voided LAST
    await repo.updateSaleStatus(client, saleId, "voided");

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

// exports.getAllSales = async () => {
//   return await repo.getAllSales();
// };

exports.getAllSales = async (filters) => {
  return await repo.getAllSales(filters);
};

// exports.getSalesBySalesperson = async (salespersonId) => {
//   return await repo.getSalesBySalesperson(salespersonId);
// };

exports.getSalesBySalesperson = async (salespersonId, filters = {}) => {
  return await repo.getSalesBySalesperson(salespersonId, filters);
};

exports.reviseSale = async (saleId, updatedData, user) => {
  const client = await db.connect();

  try {
    await client.query("BEGIN");

    // 1️⃣ Lock original sale
    const originalSaleRes = await client.query(
      `SELECT * FROM sales WHERE id = $1 FOR UPDATE`,
      [saleId],
    );

    if (originalSaleRes.rows.length === 0) {
      throw new Error("Original sale not found");
    }

    const originalSale = originalSaleRes.rows[0];

    if (originalSale.sale_status === "voided") {
      throw new Error("Cannot revise a voided sale");
    }

    // 🔒 Prevent double revision
    if (originalSale.sale_type === "revised") {
      throw new Error("Sale already revised");
    }

    // 2️⃣ Reverse stock
    const originalItems = await repo.getSaleItems(client, saleId);

    for (const item of originalItems) {
      await stockService.adjustStock(
        item.product_id,
        item.quantity,
        "sale_revision_reverse",
      );
    }

    // Reverse payment if original was paid
    if (originalSale.payment_status === "paid") {
      await paymentsRepo.reversePaymentBySaleId(client, saleId);
    }

    // 3️⃣ Mark original sale as revised
    await client.query(`UPDATE sales SET sale_type = 'revised' WHERE id = $1`, [
      saleId,
    ]);

    // 4️⃣ Recalculate new sale amounts
    const VAT_PERCENTAGE = 15;

    let grossSubtotal = 0;
    updatedData.items.forEach((i) => {
      grossSubtotal += i.quantity * i.unit_price;
    });

    const discountAmount = Number(updatedData.discount_amount || 0);

    const vatAmount = +(grossSubtotal * (VAT_PERCENTAGE / 100)).toFixed(2);

    const totalAmount = +(grossSubtotal + vatAmount - discountAmount).toFixed(
      2,
    );

    // 5️⃣ Insert new sale (REVISION)
    const newSaleRes = await client.query(
      `
      INSERT INTO sales
      (
        salesperson_id,
        customer_id,
        subtotal_amount,
        discount_amount,
        vat_percentage,
        vat_amount,
        total_amount,
        payment_method,
        payment_status,
        original_sale_id,
        sale_type
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'revision')
      RETURNING *
      `,
      [
        originalSale.salesperson_id,
        updatedData.customer_id,
        grossSubtotal,
        discountAmount,
        VAT_PERCENTAGE,
        vatAmount,
        totalAmount,
        updatedData.payment_method,
        updatedData.payment_status,
        saleId,
      ],
    );

    const newSale = newSaleRes.rows[0];

    // 6️⃣ Insert new sale items
    for (const item of updatedData.items) {
      const productRes = await client.query(
        `SELECT name, name_ar FROM products WHERE id = $1`,
        [item.product_id],
      );

      const product = productRes.rows[0];

      await client.query(
        `
        INSERT INTO sale_items
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
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        `,
        [
          newSale.id,
          item.product_id,
          product.name,
          product.name_ar,
          item.quantity,
          item.quantity,
          item.unit_price,
          item.discount || 0,
          item.quantity * (item.unit_price - (item.discount || 0)),
        ],
      );

      await stockService.adjustStock(
        item.product_id,
        -item.quantity,
        "sale_revision_new",
      );
    }

    // Create payment for revised sale if paid
    if (updatedData.payment_status === "paid") {
      await paymentsRepo.createPayment(client, {
        saleId: newSale.id,
        customerId: updatedData.customer_id,
        amount: totalAmount,
        method: updatedData.payment_method || "cash",
        status: "paid",
      });
    }

    await client.query("COMMIT");
    return newSale;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};
