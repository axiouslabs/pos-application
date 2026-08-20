const express = require("express");
const cors = require("cors");
require("dotenv").config();
const app = express();
const errorHandler = require("./src/middleware/errorHandler");
const authRoutes = require("./src/api/auth/auth.routes");
const productRoutes = require("./src/api/products/products.routes");
const customerRoutes = require("./src/api/customers/customers.routes");
const saleRoutes = require("./src/api/sales/sales.routes");
const reportRoutes = require("./src/api/reports/reports.routes");
const invoiceRoutes = require("./src/api/printing/invoice.routes");
const paymentRoutes = require("./src/api/payments/payments.routes");
const dashboardRoutes = require("./src/api/dashboard/dashboard.routes");
const stockRoutes = require("./src/api/stock/stock.routes");
const uploadProductImage = require("./src/middleware/uploadProductImage");
const userRoutes = require("./src/api/users/user.routes");

//middleware
app.use(
  cors({
    origin: "*", // allow all origins (for development)
    methods: "GET,HEAD,PUT,PATCH,POST,DELETE",
    // allowedHeaders: "Content-Type, Authorization",
    allowedHeaders: "Content-Type, Authorization, ngrok-skip-browser-warning",
    credentials: true,
  })
);

app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/customers", customerRoutes);
app.use("/api/sales", saleRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/invoices", invoiceRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/stock", stockRoutes);
app.use("/api/users", userRoutes);
// Serve uploaded files
app.use("/uploads", express.static("uploads"));

//test route
app.get("/", (req, res) => {
  res.send("ShopX Backend Running 🚀");
});

app.use((req, res) => {
  res.status(404).json({ message: "Route not found" });
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
