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
// app.post('/api/generate-goal', verifyToken, async (req, res) => {
//   const { prompt } = req.body;

//   if (!prompt) {
//     return res.status(400).json({ error: 'Prompt is required' });
//   }

//   try {
// const response = await AIclient.responses.create({
//       model: 'gpt-4.1',
//       input: [
//         {
//           role: 'system',
//           content: 'You are an experienced mentor. Ask the user the following questions one at a time, waiting for each answer before continuing: 1) Describe your current situation in detail (Point A). 2) What resources or strengths do you have that could help you reach your goal? 3) Describe your lifestyle. 4) Describe in detail the future state you want to reach (Point B). After all answers are received, respond using only this structure: 1. Point A 2. Point B 3. Steps to achieve the goal (minimum two logical and realistic steps). Do not include any extra text or formatting. Respond in the same language the user uses (English or Russian).'
//         },
//         {
//           role: 'user',
//           content: prompt
//         }
//       ],
//     });

//     return res.status(200).json(response.output_text);
//   } catch (error) {
//     console.error('Error with OpenAI API:', error.message);
//     res.status(500).json({ error: 'Failed to generate goal plan', details: error.message });
//   }
// });

// Store conversation history in memory (for simplicity; use a database for production)
const conversationHistory = new Map();

// System prompt for the AI mentor
const systemGoalPrompt = `
You are an AI mentor focused on helping users set and achieve personal goals. Your tone is encouraging, empathetic, and motivational, like a supportive coach. Follow these rules:
1. Ask exactly one question per message to guide the user toward defining a goal. Keep questions open-ended and relevant to their aspirations.
2. After 3–5 exchanges, summarize the conversation into a structured goal with:
   - Goal Description: A clear, concise statement of the goal.
   - Point A: The user's current situation or starting point.
   - Point B: The desired outcome or endpoint.
   - Steps: A list of 3–5 actionable steps to achieve the goal.
   - Tips: 2–3 motivational tips to stay on track.
3. Maintain context by using the full conversation history.
4. If the user provides enough information early, generate the goal summary sooner.
5. Do not repeat questions unless necessary for clarification.
6. End each message with a single question to keep the conversation flowing.
Example flow:
- Message 1: "What’s something you’ve always wanted to achieve in your personal or professional life?"
- Message 2: "That sounds exciting! What’s one challenge you face in pursuing this goal?"
- Message 3: "Got it! What skills or resources do you currently have that could help you achieve this?"
- Message 4: Summarize into goal structure if enough information is provided.
`;

app.post('/api/generate-goal', verifyToken, async (req, res) => {
  try {
    const { message } = req.body;
    const user_id = req.userId;

    // Validate input
    if (!user_id || !message) {
      return res.status(400).json({ error: 'user_id and message are required' });
    }

    // Get or initialize conversation history for the user
    let conversation = conversationHistory.get(user_id) || [
      { role: 'system', content: systemGoalPrompt },
      { role: 'assistant', content: 'What’s something you’ve always wanted to achieve in your personal or professional life?' },
    ];

    // Append user's message
    conversation.push({ role: 'user', content: message });

    // Call OpenAI API
    const response = await AIclient.chat.completions.create({
      model: 'gpt-4.1', // or 'gpt-3.5-turbo' for cost-efficiency
      messages: conversation,
      max_tokens: 500,
      temperature: 0.7, // Balanced creativity
    });

    const aiMessage = response.choices[0].message.content;

    // Append AI's response to conversation history
    conversation.push({ role: 'assistant', content: aiMessage });

    // Store updated conversation history
    conversationHistory.set(user_id, conversation);

    // Check if the AI response contains a goal summary (based on format)
    const goalPattern = /Goal Description:/i;
    if (goalPattern.test(aiMessage)) {
      // Parse the AI response to extract goal components
      const goalMatch = aiMessage.match(/Goal Description: (.*?)(?:\n|$)/i);
      const pointAMatch = aiMessage.match(/Point A: (.*?)(?:\n|$)/i);
      const pointBMatch = aiMessage.match(/Point B: (.*?)(?:\n|$)/i);
      const stepsMatch = aiMessage.match(/Steps: \[(.*?)\](?:\n|$)/i);
      const tipsMatch = aiMessage.match(/Tips: \[(.*?)\](?:\n|$)/i);

      const goalData = {
        description: goalMatch ? goalMatch[1].trim() : '',
        pointA: pointAMatch ? pointAMatch[1].trim() : '',
        pointB: pointBMatch ? pointBMatch[1].trim() : '',
        steps: stepsMatch ? stepsMatch[1].split(';').map(s => s.trim()) : [],
        tips: tipsMatch ? tipsMatch[1].split(';').map(s => s.trim()) : [],
      };

      // Clear conversation history after goal is saved
      conversationHistory.delete(user_id);

      return res.status(200).json({
        message: aiMessage,
        goalData: goalData
      });
    }

    // Return AI response if no goal summary yet
    return res.status(200).json({ message: aiMessage });
  } catch (error) {
    console.error('Error in mentor chat:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// // Endpoint to generate event plan
// app.post('/api/generate-event', verifyToken, async (req, res) => {
//   const { prompt } = req.body;

//   if (!prompt) {
//     return res.status(400).json({ error: 'Prompt is required' });
//   }

//   try {
// const response = await AIclient.chat.completions.create({
//       model: 'gpt-4.1',
//       input: [
//         {
//           role: 'system',
//           content: 'You are an experienced mentor. Before generating a short-term goal description (event), ask the user the following questions one at a time, waiting for each answer before continuing: 1) What exactly do you want to do in the near future? 2) Why do you want to do this? (what result or effect are you expecting?) 3) When do you plan to do it? 4) Where will it take place? (if applicable) 5) What resources or conditions do you need to complete this action? 6) Is there anything that could interfere with or complicate it? After receiving all the answers, provide one clear and concise event description (i.e., short-term action), with no headings, no explanation, and no formatting. Respond in the same language the user uses.'
//         },
//         {
//           role: 'user',
//           content: prompt
//         }
//       ],
//     });

//     return res.status(200).json(response.output_text);
//   } catch (error) {
//     console.error('Error with OpenAI API:', error.message);
//     res.status(500).json({ error: 'Failed to generate event plan', details: error.message });
//   }
// });



// System prompt for the AI mentor
const systemEventPrompt = `
You are an AI mentor focused on helping users plan events. Your tone is encouraging, empathetic, and motivational, like a supportive organizer. Follow these rules:
1. Ask exactly one question per message to guide the user toward defining an event (e.g., a meetup, workshop, or celebration). Keep questions open-ended and relevant to their plans.
2. After 3–5 exchanges, summarize the conversation into a structured event with:
   - Description: A clear, concise statement of the event.
   - Date and Time: A specific date and time in ISO 8601 format (e.g., "2025-08-15T10:00:00Z").
3. Maintain context by using the full conversation history.
4. If the user provides enough information early, generate the event summary sooner.
5. Do not repeat questions unless necessary for clarification.
6. End each message with a single question to keep the conversation flowing.
Example flow:
- Message 1: "What kind of event would you like to plan, like a community gathering, a workshop, or something else?"
- Message 2: "That sounds fun! What’s the main purpose or theme of this event?"
- Message 3: "Great idea! When would you like to hold this event?"
- Message 4: Summarize into event structure if enough information is provided.
`;

app.post('/api/generate-event', verifyToken, async (req, res) => {
  try {
    const { message } = req.body;
    const user_id = req.userId;

    // Validate input
    if (!user_id || !message) {
      return res.status(400).json({ error: 'user_id and message are required' });
    }

    // Get or initialize conversation history for the user
    let conversation = conversationHistory.get(user_id) || [
      { role: 'system', content: systemEventPrompt },
      { role: 'assistant', content: 'What kind of event would you like to plan, like a community gathering, a workshop, or something else?' },
    ];

    // Append user's message
    conversation.push({ role: 'user', content: message });

    // Call OpenAI API
    const response = await AIclient.chat.completions.create({
      model: 'gpt-4.1', // Use gpt-4o (or gpt-3.5-turbo for cost-efficiency)
      messages: conversation,
      max_tokens: 300,
      temperature: 0.7,
    });

    const aiMessage = response.choices[0].message.content;

    // Append AI's response to conversation history
    conversation.push({ role: 'assistant', content: aiMessage });

    // Store updated conversation history
    conversationHistory.set(user_id, conversation);

    // Check if the AI response contains an event summary
    const eventPattern = /Description:/i;
    if (eventPattern.test(aiMessage)) {
      // Parse the AI response to extract event components
      const descriptionMatch = aiMessage.match(/Description: (.*?)(?:\n|$)/i);
      const dateTimeMatch = aiMessage.match(/Date and Time: (.*?)(?:\n|$)/i);

      const eventData = {
        description: descriptionMatch ? descriptionMatch[1].trim() : '',
        date_time: dateTimeMatch ? dateTimeMatch[1].trim() : '',
      };

      // Clear conversation history after event is generated
      conversationHistory.delete(user_id);

      return res.status(200).json({
        message: aiMessage,
        event: eventData,
        status: 'Event generated',
      });
    }

    // Return AI response if no event summary yet
    return res.status(200).json({ message: aiMessage });
  } catch (error) {
    console.error('Error in generate-event:', error.message);
    if (error.code === 'invalid_request_error') {
      return res.status(400).json({ error: 'Invalid OpenAI model or request' });
    }
    if (error.code === 'rate_limit_exceeded') {
      return res.status(429).json({ error: 'OpenAI API rate limit exceeded' });
    }
    return res.status(500).json({ error: 'Internal server error' });
  }
});


// // Start the server
app.listen(process.env.PORT, () => {
  console.log(`Server running at http://localhost:${process.env.PORT}`);
});