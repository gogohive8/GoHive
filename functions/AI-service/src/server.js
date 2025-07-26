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
          content: 'You are an experienced mentor. When the user describes their situation or goal, you must ask clarifying questions to better understand what they truly want, where they are now, what obstacles they face, and what resources or constraints they have. Keep the dialogue short but deep. Ask follow-up questions if needed. Only after you fully understand their situation, provide the final response strictly in this format: 1. Goal 2. Point A (current state) 3. Point B (desired state) 4. Steps to achieve the goal. The final response must include only these four points, with no additional text. Respond in the same language the user uses (Russian or English).'
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
          content: 'You are a professional strategist and mentor for event planning. When the user submits an event idea or request, ask clarifying questions to understand the purpose of the event, the target audience, the format, the location (if any), as well as any constraints or specific wishes. Keep the dialogue brief but meaningful. Once you clearly understand the event concept, generate one concise event description. Do not include explanations or formatting — only the event description. Respond in the same language the user uses.'
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