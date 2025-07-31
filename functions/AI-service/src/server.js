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
          content: 'You are an experienced mentor. Ask the user the following questions one at a time, waiting for each answer before continuing: 1) Describe your current situation in detail (Point A). 2) What resources or strengths do you have that could help you reach your goal? 3) Describe your lifestyle. 4) Describe in detail the future state you want to reach (Point B). After all answers are received, respond using only this structure: 1. Point A 2. Point B 3. Steps to achieve the goal (minimum two logical and realistic steps). Do not include any extra text or formatting. Respond in the same language the user uses (English or Russian).'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
    });

    return res.status(200).json(response.output_text);
  } catch (error) {
    console.error('Error with OpenAI API:', error.message);
    res.status(500).json({ error: 'Failed to generate goal plan', details: error.message });
  }
});

// Endpoint to generate event plan
app.post('/api/generate-event', verifyToken, async (req, res) => {
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
          content: 'You are an experienced mentor. Before generating a short-term goal description (event), ask the user the following questions one at a time, waiting for each answer before continuing: 1) What exactly do you want to do in the near future? 2) Why do you want to do this? (what result or effect are you expecting?) 3) When do you plan to do it? 4) Where will it take place? (if applicable) 5) What resources or conditions do you need to complete this action? 6) Is there anything that could interfere with or complicate it? After receiving all the answers, provide one clear and concise event description (i.e., short-term action), with no headings, no explanation, and no formatting. Respond in the same language the user uses.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
    });

    return res.status(200).json(response.output_text);
  } catch (error) {
    console.error('Error with OpenAI API:', error.message);
    res.status(500).json({ error: 'Failed to generate event plan', details: error.message });
  }
});

// Start the server
app.listen(process.env.PORT, () => {
  console.log(`Server running at http://localhost:${process.env.PORT}`);
});