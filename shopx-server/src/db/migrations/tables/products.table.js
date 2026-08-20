module.exports = async(client)=>{
    try{
        console.log("Checking if products table already exist in database ");

        const result = await client.query(`
                  SELECT to_regclass('public.products') AS table_name;

            `);

            const tableExists =result.rows[0].table_name !==null;

            if(tableExists){
                     console.log("✔️ 'products' table already exists.");
return;
   

            }
              console.log("⏳ Creating 'products' table...");

               await client.query(`
      CREATE TABLE products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        name_ar VARCHAR(100) NOT NULL,       -- Arabic name (NEW)
        price NUMERIC(10, 2) NOT NULL,
        quantity NUMERIC(10,2) DEFAULT 0,       
        code TEXT,    
        category TEXT, 
        vat NUMERIC(5,2) DEFAULT 0,  
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

     console.log("✅ 'products' table created successfully!");

    }catch(err){
         console.error("❌ Failed to create 'products' table:", err.message);
   
    }
};

/*This table is the foundation for:

Stock management

Sales creation

Sales reports

Billing

Receipts

Admin dashboard

Everything starts from PRODUCTS. */