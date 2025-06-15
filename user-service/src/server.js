const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const redis = require('redis');
const cors = require('cors');

require('dotenv').config({ path: __dirname + '/../.env'});

const app = express();
app.use(express.json());
app.use(cors({
  origin: 'http://localhost:40723', // Replace with your Flutter web app's URL
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

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

// email registration

app.post('/register/email', async (req, res) => {
  try{
    const { name, surname, username, age, mail, phone, password} = req.body;

    // check if email is exist
    const { data: existingUser } = await supabase.auth.admin.getUserByEmail(mail);
    if (existingUser) {
      return res.status(400).json({error: 'Email already exist'});
    }

    // Check if username is already exist
    if (username) {
      const { data: existingUsername } = await supabase.from('users').select('username').eq('username', username).single();

      if (existingUsername){
        return res.status(400).json({ error: 'Username already exist '});
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const {data: authData, error: authError} = await supabase.auth.admin.createUser({
      email: mail,
      password: hashedPassword,
      phone: phone || null,
      email_confirm: true,
    });
    if (authError) {
      return res.status(400).json({error: authError.message});
    }

    // Insert additional information into public.users table
    const { data: user, error } = await supabase.from('users').insert([
      {
        id: authData.user.id,
        name,
        surname,
        username,
        age
      },
    ]).select().single();
    if (error){
      await supabase.auth.admin.deleteUser(authData.user.id);
      return res.status(400).json({ error: error.message });
    }

    // Generate JWT
    const token = jwt.sign({ id: authData.user.id }, process.env.JWT_SECRET, {expiresIn: '1h'});

    // Cache JWT in redis
    await redisClient.setEx(`jwt:${token}`, 3600, authData.user.id);

    res.status(200).json({
      user: {
        id: user.id,
        name: user.name,
        surname: user.surname,
        username: user.username,
        age: user.age,
        mail: authData.user.email,
        phone: authData.user.phone,
      },
      token,
    });
  } catch (error) {
    res.status(400).json({ error: error.message});
  }
});



// OAuth registration/login (Google/Apple)
app.post('/register/oauth', async (req, res) => {
  try {
    const { provider, access_token } = req.body;
    if (!['google', 'apple'].includes(provider) || !access_token) {
      return res.status(400).json({ error: 'Invalid provider or access token' });
    }

    // Sign in with OAuth token
    const { data: session, error: authError } = await supabase.auth.signInWithOAuth({
      provider,
      options: { access_token },
    });
    if (authError) {
      return res.status(400).json({ error: authError.message });
    }

    const { user: authUser } = session;

    // Check if user exists in public.users
    let { data: user, error: fetchError } = await supabase
      .from('users')
      .select('*')
      .eq('id', authUser.id)
      .single();

    if (fetchError && fetchError.code === 'PGRST116') {
      // User doesn't exist, create new user in public.users
      const { data: newUser, error: insertError } = await supabase
        .from('users')
        .insert([
          {
            id: authUser.id,
            name: authUser.user_metadata.full_name?.split(' ')[0] || 'Unknown',
            surname: authUser.user_metadata.full_name?.split(' ')[1] || 'Unknown',
            username: authUser.user_metadata.preferred_username || null,
            age: null,
          },
        ])
        .select()
        .single();
      if (insertError) {
        return res.status(400).json({ error: insertError.message });
      }
      user = newUser;
    } else if (fetchError) {
      return res.status(400).json({ error: fetchError.message });
    }

      // Generate JWT
    const token = jwt.sign({ id: authUser.id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    // Cache JWT and user data in Redis
    await redisClient.setEx(`jwt:${token}`, 3600, authUser.id);

    res.json({
      user: {
        id: user.id,
        name: user.name,
        surname: user.surname,
        username: user.username,
        age: user.age,
        mail: authUser.email,
        phone: authUser.phone,
      },
      token,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});



// Email-based login
app.post('/login', async (req, res) => {
  try {
    const { mail, password } = req.body;
    if (!mail || !password) {
      return res.status(400).json({ error: 'Missing email or password' });
    }

    // Authenticate with Supabase
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: mail,
      password,
    });
    if (authError) {
      return res.status(401).json({ error: authError.message });
    }

    // Fetch user data from public.users
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', authData.user.id)
      .single();
    if (error) {
      return res.status(400).json({ error: error.message });
    }

    // Generate JWT
    const token = jwt.sign({ id: authData.user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    // Cache JWT and user data in Redis
    await redisClient.setEx(`jwt:${token}`, 3600, authData.user.id);

    res.json({
      user: {
        id: user.id,
        name: user.name,
        surname: user.surname,
        username: user.username,
        age: user.age,
        mail: authData.user.email,
        phone: authData.user.phone,
      },
      token,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Logout
app.post('/logout', verifyToken, async (req, res) => {
  try {
    const token = req.headers['authorization'].split(' ')[1];
    await redisClient.del(`jwt:${token}`);
    res.json({ message: 'Logged out' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});


const PORT = process.env.PORT;
app.listen(PORT, () => console.log(`Server running on port: ${PORT}`));