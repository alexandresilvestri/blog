import 'dotenv/config';
import { drizzle } from 'drizzle-orm/postgres-js';

const db = drizzle({ 
  connection: { 
    connectionString: process.env.DATABASE_URL!,
    ssl: true
  }
})

