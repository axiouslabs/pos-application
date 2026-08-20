exports.validateSale = (data) => {
  const errors = [];

//   if (!data.salesperson_id) errors.push("Salesperson is required");
  if (!data.customer_id) errors.push("Customer is required");
  if (!data.items || data.items.length === 0)
    errors.push("At least one sale item is required");

  data.items.forEach((item, i) => {
    if (!item.product_id) errors.push(`Item ${i + 1}: Product id missing`);
    if (!item.quantity || item.quantity <= 0)
      errors.push(`Item ${i + 1}: Quantity must be > 0`);
    if (!item.unit_price || item.unit_price <= 0)
      errors.push(`Item ${i + 1}: Unit price must be > 0`);
  });

  return errors;
};
