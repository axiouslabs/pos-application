// const checkAdmin = (req, res, next) => {
//   if (req.user.user_type !== "admin") {
//     res.status(403);
//     throw new Error("Access denied. Admins only.");
//   }
//   next();
// };

// module.exports = checkAdmin;



const repo = require("../api/auth/auth.repository");

const checkAdmin = async (req, res, next) => {
  try {
    // 1️⃣ Count how many admins exist
    const adminCount = await repo.countAdmins();

    // 2️⃣ If NO admin exists → allow request (first admin setup)
    if (adminCount === 0) {
      return next();
    }

    // 3️⃣ If admin exists → require req.user
    if (!req.user || req.user.user_type !== "admin") {
      res.status(403);
      throw new Error("Access denied. Admins only.");
    }

    next();
  } catch (err) {
    res.status(500);
    throw new Error("Server error in checkAdmin");
  }
};

module.exports = checkAdmin;
