const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const redis = require('redis');
const cors = require('cors');

require('dotenv').config( { path: __dirname + '/../.env'} );

const app = express();
app.use(express.json());
app.use(cors({
  origin: 'http://localhost:40723', // Replace with your Flutter web app's URL
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

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
// Proxy routes to microservices
const proxyOptions = (target, pathRewrite) => ({
  target,
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite,
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying request to ${proxyReq.path} on ${target}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from ${target} for ${req.path}: ${proxyRes.statusCode}`);
    // Buffer response to handle errors
    let body = [];
    proxyRes.on('data', chunk => body.push(chunk));
    proxyRes.on('end', () => {
      body = Buffer.concat(body).toString();
      if (proxyRes.statusCode >= 400) {
        console.warn(`Error response: ${body}`);
      }
    });
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: 'Proxy error' });
  },
});

// Routes
app.use('/api/register/email', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/register/email': '/register/email',
})));

app.use('/api/register/oauth', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/register/oauth': '/register/oauth',
})));

app.use('/api/login', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/login': '/login',
})));

app.use('/api/logout', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/logout': '/logout',
})));

app.use('/api/users', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/users': '/users',
})));

app.use('/api/products', createProxyMiddleware(proxyOptions('http://localhost:3002', {
  '^/api/products': '/products',
})));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`Unhandled error: ${err.stack}`);
  res.status(500).json({ error: 'Internal server error' });
});
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API Gateway running on port ${PORT}`));