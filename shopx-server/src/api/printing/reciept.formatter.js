exports.formatReceipt = (sale, items) => {
  return {
    shopName: "Your Distribution Company",
    date: new Date(sale.created_at).toLocaleString(),
    saleId: sale.id,
    customer: sale.customer_name,
    salesperson: sale.salesperson_name,
    items: items.map(i => ({
      name: i.name,
      qty: i.quantity,
      price: i.unit_price,
      total: i.total_price,
    })),
    total: sale.total_amount
  };
};
