const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const redis = require('redis');

require('dotenv').config({ path: __dirname + '/../.env'});

const app = express();
app.use(express.json());

// Connect to supabase client
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

// Redis connection
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().then(() => console.log('Redis connected'));



// Middleware to verify JWT
const verifyToken = async (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const storedToken = await redisClient.get(`jwt:${token}`);
    if (!storedToken) return res.status(401).json({ error: 'Invalid or expired token' });

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Routes
// #TODO:
// initialize route for registration and authorization users, also for logout


const PORT = process.env.PORT;
app.listen(PORT, () => console.log(`Server running on port: ${PORT}`));