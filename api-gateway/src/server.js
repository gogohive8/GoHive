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
// Proxy routes to microservices with path rewriting
app.use('/api/register/email', createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api/register/email': '/api/register/email', // Переписываем путь
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on user-service`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from user-service for ${req.path}: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
}));

app.use('/api/register/oauth', createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api/register/oauth': '/register/oauth', // Переписываем путь
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on user-service`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from user-service for ${req.path}: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
}));

app.use('/api/login', createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api/login': '/login', // Переписываем путь, если нужно
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on user-service`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from user-service for ${req.path}: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
}));

app.use('/api/logout', createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api/logout': '/logout', // Переписываем путь, если нужно
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on user-service`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from user-service for ${req.path}: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
}));

app.use('/api/users', createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api/users': '/users', // Переписываем путь, если нужно
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on user-service`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from user-service for ${req.path}: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
}));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API Gateway running on port ${PORT}`));