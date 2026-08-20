const asyncHandler = require("express-async-handler");
const service = require("./dashboard.service");

exports.getDashboard = asyncHandler(async (req, res) => {
  const data = await service.getDashboardData();
  res.json(data);
});
