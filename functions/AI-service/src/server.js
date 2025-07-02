const express = require('express');
const jwt = require("jsonwebtoken");
const cors = require('cors');
const path = require('path');
const OpenAI = require('openai');
require('dotenv').config({ path: __dirname + '/../.env'});

const app = express();

// Middleware to parse JSON bodies
app.use(cors({
  origin: [
    'https://gohive-c253c.web.app',
    'https://gohive-c253c.firebaseapp.com/',
    'http://127.0.0.1:5000' // For local Firebase emulator
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true // If cookies or auth headers are used
}));

app.use(express.json());

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('JSON parsing error:', err.message, 'Request body:', req.body);
    return res.status(400).json({ error: 'Invalid JSON payload' });
  }
  console.error('Unexpected error:', err.stack);
  res.status(500).json({ error: 'Internal server error' });
});


// Log all incoming requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] Incoming request: ${req.method} ${req.path}`);
  console.log(`Request headers: ${JSON.stringify(req.headers)}`);
  console.log(`Request body: ${JSON.stringify(req.body)}\n`);
  next();
});

// Log all responses
app.use((req, res, next) => {
  const originalSend = res.send;
  res.send = function (body) {
    console.log(`[${new Date().toISOString()}] Response for ${req.method} ${req.path}`);
    console.log(`Response status: ${res.statusCode}`);
    console.log(`Response headers: ${JSON.stringify(res.getHeaders())}`);
    console.log(`Response body: ${typeof body === 'string' ? body : JSON.stringify(body)}\n`);
    return originalSend.call(this, body);
  };
  next();
});

// Middleware to verify JWT
const verifyToken = async (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};


const AIclient = new OpenAI({apiKey: process.env.OPENAI_API});

// Endpoint to generate goal plan
app.post('/api/generate-goal', verifyToken, async (req, res) => {
  const { prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: 'Prompt is required' });
  }

  try {
const response = await AIclient.responses.create({
      model: 'gpt-4.1',
      input: [
        {
          role: 'system',
          content: 'You are a helpful assistant that generates a goal plan based on user input. Given a description of a person\'s current state or situation (which may include text or a description of photos), provide a structured response with: 1) Point A: The current state of the person. 2) Point B: The desired end state where the goal is achieved. 3) Steps: A list of actionable steps to move from Point A to Point B. Format the response clearly with these sections.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
    });

    return res.status(200).json(response);
  } catch (error) {
    console.error('Error with OpenAI API:', error.message);
    res.status(500).json({ error: 'Failed to generate goal plan', details: error.message });
  }
});

// Start the server
app.listen(process.env.PORT, () => {
  console.log(`Server running at http://localhost:${process.env.PORT}`);
});