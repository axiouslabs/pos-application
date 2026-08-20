require("dotenv").config();
const createTables = require("./migrations/createTables");

(async()=>{
    try{
          console.log("📦 Starting database migrations...");

          await createTables();
          console.log("🎉 Database is ready!");

    }catch(err){
            console.error("❌ Migration error:", err);
            process.exit(1);
    }
})();