const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

require('dotenv').config( { path: __dirname + '/../.env'} );

const app = express();

const limiter = rateLimit({
  windowMs: 5 * 60 * 1000, // time limit of requests
  max: 5, // requests limit
});

app.use(limiter);
app.set('trust proxy', 1);

app.use(cors({
  origin: 'http://localhost:4200', // Replace with your Flutter web app's URL
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));


app.use(express.json({ limit: '10mb' }));


app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('JSON parsing error:', err.message, 'Request body:', req.body);
    return res.status(400).json({ error: 'Invalid JSON payload' });
  }
  console.error('Unexpected error:', err.stack, 'Request body:', req.body);
  res.status(500).json({ error: 'Internal server error' });
});

// Log all incoming requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] Incoming request: ${req.method} ${req.path}`);
  console.log(`Request headers: ${JSON.stringify(req.headers)}`);
  console.log(`Request body: ${JSON.stringify(req.body)}`);
  next();
});


// Proxy routes to microservices
const proxyOptions = (target, pathRewrite) => ({
  target,
  changeOrigin: true,
  logLevel: 'debug',
  pathRewrite,
  timeout: 30000,
  proxyTimeout: 30000,
  onProxyReq: (proxyReq, req, res) => {
    console.log(`[${new Date().toISOString()}] Proxying request to ${target}${req.path}`);
    console.log(`Proxy request headers: ${JSON.stringify(req.headers)}`);
    console.log(`Proxy request body: ${JSON.stringify(req.body)}`);
    proxyReq.on('error', (err) => {
      console.error(`[${new Date().toISOString()}] Proxy request error: ${err.message}`);
    });
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`[${new Date().toISOString()}] Received response from ${target} for ${req.path}: ${proxyRes.statusCode}`);
    let body = [];
    proxyRes.on('data', chunk => body.push(chunk));
    proxyRes.on('end', () => {
      body = Buffer.concat(body).toString();
      console.log(`Response body: ${body}`);
      res.status(proxyRes.statusCode);
      for (const [key, value] of Object.entries(proxyRes.headers)) {
        res.setHeader(key, value);
      }
      res.end(body);
    });
  },
  onError: (err, req, res) => {
    console.error(`[${new Date().toISOString()}] Proxy error for ${req.path}: ${err.message}`);
    res.status(500).json({ error: `Proxy error: ${err.message}` });
  },
});

// Public proxy routes (no JWT verification)
app.use('/api/register/email', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/register/email': '/register/email',
})));

app.use('/api/register/oauth', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/register/oauth/google': '/register/oauth/google',
})));

app.use('/api/login', createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/login': '/login',
})));


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

// Protected routes (require JWT)
app.use('/api/logout', verifyToken, createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/logout': '/logout',
})));

app.use('/api/users', verifyToken, createProxyMiddleware(proxyOptions('http://localhost:3001', {
  '^/api/users': '/users',
})));


// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`Unhandled error: ${err.stack}`);
  res.status(500).json({ error: 'Internal server error' });
});
const PORT = process.env.PORT;
app.listen(PORT, () => console.log(`API Gateway running on port ${PORT}`));