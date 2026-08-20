// const {Pool}=require("pg");
// require("dotenv").config();

// const pool = new Pool({
//  user:process.env.DB_USER,
//  host:process.env.DB_HOST,
//  database:process.env.DB_DATABASE,
//  password:process.env.DB_PASSWORD,
//  port:process.env.DB_PORT
// });

// module.exports=pool;


// const { Pool } = require("pg");
// require("dotenv").config();

// const pool = new Pool({
//   connectionString: process.env.NEON_DB_URL,
//   ssl: {
//     rejectUnauthorized: false,
//   },
// });

// module.exports = pool;

const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

module.exports = pool;

