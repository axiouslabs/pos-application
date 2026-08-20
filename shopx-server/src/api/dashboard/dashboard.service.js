const repo = require("./dashboard.repository");

exports.getDashboardData = async () => {
  const totalSales = await repo.getTotalSales();
  const totalPayments = await repo.getTotalPayments();  // optional
  const todaySales = await repo.getTodaySales();
  const topProducts = await repo.getTopProducts();
  const salesBySalesperson = await repo.getSalesBySalesperson();
  const recentSales = await repo.getRecentSales();
  const lowStock = await repo.getLowStock();
  const customerCount = await repo.getCustomerCount();
  const weeklySales = await repo.getWeeklySales();
  const totalDiscount = await repo.getTotalDiscount();

  return {
    totals: {
      gross_revenue: Number(totalSales.rows[0].total_revenue),   // correct
      total_sales: Number(totalSales.rows[0].total_sales),       // correct
      avg_order_value: Number(totalSales.rows[0].avg_order_value), // correct
      total_payments: Number(totalPayments.rows[0].total_payments), // optional

      total_customers: Number(customerCount.rows[0].total_customers),
      total_discount: Number(totalDiscount.rows[0].total_discount),

      // Net Sales = Gross − Discount
      net_sales:
        Number(totalSales.rows[0].total_revenue) -
        Number(totalDiscount.rows[0].total_discount)
    },

    charts: {
      top_products: topProducts.rows,
      sales_by_salesperson: salesBySalesperson.rows,
      weekly_summary: weeklySales.rows
    },

    tables: {
      recent_sales: recentSales.rows,
      low_stock: lowStock.rows,
    },
  };
};
