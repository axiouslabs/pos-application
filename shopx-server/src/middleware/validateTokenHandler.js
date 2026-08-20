// const asyncHandler = require("express-async-handler");
// const jwt = require("jsonwebtoken");
// const repo = require("../api/auth/auth.repository");

// const validateToken = asyncHandler(async (req, res, next) => {
//   // 1️⃣ Check if ANY admin exists
//   const adminCount = await repo.countAdmins();

//   // 2️⃣ If NO admin exists → bypass token validation
//   if (adminCount === 0) {
//     return next();
//   }

//   // 3️⃣ After admin exists → enforce token validation
//   let authHeader = req.headers.Authorization || req.headers.authorization;

//   if (authHeader && authHeader.startsWith("Bearer")) {
//     const token = authHeader.split(" ")[1];

//     jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, decoded) => {
//       if (err) {
//         res.status(401);
//         throw new Error("User is not authorized");
//       }
//       // 🔥 CASE 1: tempToken → { id: userId }
//       if (decoded.id) {
//         req.user = { id: decoded.id };
//       }

//       // 🔥 CASE 2: normal login token → { user: {...} }
//       else if (decoded.user) {
//         req.user = decoded.user;
//       }
//       next();
//     });
//   } else {
//     res.status(401);
//     throw new Error("User is not authorized or Token is missing");
//   }
// });

// module.exports = validateToken;

const asyncHandler = require("express-async-handler");
const jwt = require("jsonwebtoken");
const repo = require("../api/auth/auth.repository");

const validateToken = asyncHandler(async (req, res, next) => {
  // 1️⃣ Allow app bootstrap when no admin exists
  const adminCount = await repo.countAdmins();
  if (adminCount === 0) {
    return next();
  }

  // 2️⃣ Read Authorization header
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      code: "NO_ACCESS_TOKEN",
      message: "Access token missing",
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);

    // tempToken (OTP / owner flow)
    if (decoded.id) {
      req.user = { id: decoded.id };
    }
    // normal login token
    else if (decoded.user) {
      req.user = decoded.user;
    }

    return next();
  } catch (err) {
    // 🔑 MOST IMPORTANT CHANGE
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({
        code: "ACCESS_TOKEN_EXPIRED",
        message: "Access token expired",
      });
    }

    return res.status(401).json({
      code: "INVALID_ACCESS_TOKEN",
      message: "Invalid access token",
    });
  }
});

module.exports = validateToken;
