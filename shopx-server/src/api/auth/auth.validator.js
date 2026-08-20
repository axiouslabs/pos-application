const registerValidator = (req, res, next) => {
  const { username, email, password,phone } = req.body;


  if (!username || !email || !password||!phone) {
    res.status(400);
    return next(new Error("Username, email, password and phone are required"));
  }
  next();
};

const loginValidator = (req, res, next) => {
  const { username, password } = req.body;
  if (!username || !password) {
    res.status(400);
    return next(new Error("username and password required"));
  }
  next();
};

module.exports = { registerValidator, loginValidator };
