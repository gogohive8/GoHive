const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const redis = require('redis');

require('dotenv').config( { path: __dirname + '/../.env'} );

const app = express();

// Redis connection
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().then(() => console.log('Redis connected'));

// Middleware to verify JWT
const verifyToken = async (req, res, next) => {
  const publicPaths = ['/api/register/email', '/api/register/oauth', '/api/login'];
  if (publicPaths.includes(req.path)) return next();

  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const storedToken = await redisClient.get(`jwt:${token}`);
    if (!storedToken) return res.status(401).json({ error: 'Invalid or expired token' });

    jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

app.use(verifyToken);

// Proxy routes to microservices
app.use('/api/register/email', createProxyMiddleware({ target: 'http://localhost:3001', changeOrigin: true }));
app.use('/api/register/oauth', createProxyMiddleware({ target: 'http://localhost:3001', changeOrigin: true }));
app.use('/api/login', createProxyMiddleware({ target: 'http://localhost:3001', changeOrigin: true }));
app.use('/api/logout', createProxyMiddleware({ target: 'http://localhost:3001', changeOrigin: true }));
app.use('/api/users', createProxyMiddleware({ target: 'http://localhost:3001', changeOrigin: true }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API Gateway running on port ${PORT}`));