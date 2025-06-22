const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');
const cors = require('cors');

require('dotenv').config({ path: __dirname + '/../.env'});

const app = express();
app.use(cors({
  origin: [
    'http://gohive-d4359.web.app',
    'https://gohive-d4359.firebaseapp.com',
    'http://0.0.0.0:4200' // For local Firebase emulator
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true // If cookies or auth headers are used
}));



app.use(express.json({ limit: '10mb' }));
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


// Connect to supabase client
const supabase = createClient(process.env.SUPABASE_URL, 
  process.env.SUPABASE_SERVICE_KEY);


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

// Routes

// email registration

app.post('/register/email', async (req, res) => {
  console.log('Received /register/email request:', req.body); // Log incoming request
  try{
    const { name, surname, username, age, mail, phone, password} = req.body;

    // check if email is exist
    const { data: users, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error('Error listing users:', listError);
      return res.status(400).json({ error: listError.message });
    }
    const existingUser = users.users.find(user => user.email === mail);
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    // Check if username is already exist
    if (username) {
      const { data: existingUsername } = await supabase.from('users').select('username').eq('username', username).single();

      if (existingUsername){
        return res.status(400).json({ error: 'Username already exist '});
      }
    }


    // Create new user
    const {data: authData, error: authError} = await supabase.auth.admin.createUser({
      email: mail,
      password: password,
      phone: phone || null,
      email_confirm: true,
    });
    if (authError) {
      console.error('Error of create new user', authError.message);
      return res.status(400).json({error: authError.message});
    }

    // Insert additional information into public.users table
    const { data: user, error } = await supabase
    .schema('public')
    .from('users')
    .insert([
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
      console.error('Error of insert new user', error.message);
      return res.status(400).json({ error: error.message });
    }


    const {data: profile, error: createProfileError} = await supabase
    .schema('public')
    .from('profiles')
    .insert([
      {
        id: authData.user.id
      }
    ]);
    if (createProfileError){
      await supabase.auth.admin.deleteUser(authData.user.id);
      console.error('Error of insert new profile', createProfileError.message);
      return res.status(400).json({ error: createProfileError.message });
    }
    // Generate JWT
    const token = jwt.sign({ id: authData.user.id }, process.env.JWT_SECRET, {expiresIn: '1h'});

   res.status(200).json({
      'token' : token,
      'userID' : authData.user.id,
    });
  } catch (error) {
    console.error('Error in /register/email:', error.message);
    res.status(400).json({ error: error.message });
  }
});



// OAuth registration/login (Google/Apple)
app.post('/register/oauth/google', async (req, res) => {
  try {
    const { supabase_token } = req.body;
    if (!supabase_token) {
      return res.status(400).json({ error: 'Missing Supabase token' });
    }

    // Verify Supabase session token
    const { data: userData, error: authError } = await supabase.auth.getUser(supabase_token);
    if (authError) {
      console.error('Error verifying Supabase token:', authError.message);
      return res.status(400).json({ error: authError.message });
    }

    const authUser = userData.user;
    if (!authUser) {
      return res.status(400).json({ error: 'No user returned from Supabase' });
    }

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
        await supabase.auth.admin.deleteUser(authUser.user.id);
        console.error('Error inserting user:', insertError.message);
        return res.status(400).json({ error: insertError.message });
      }
      const {data: profile, error: createProfileError} = await supabase
        .schema('public')
        .from('profiles')
        .insert([
      {
        id: authUser.id,
      }
    ]);
      if (createProfileError){
        await supabase.auth.admin.deleteUser(authUser.user.id);
        console.error('Error of insert new profile', createProfileError.message);
        return res.status(400).json({ error: createProfileError.message });
      }
      user = newUser;
    } else if (fetchError) {
      console.error('Error fetching user:', fetchError.message);
      return res.status(400).json({ error: fetchError.message });
    }

    // Generate JWT
    const token = jwt.sign({ id: authUser.id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(200).json({
      token: token,
      userID: authUser.id,
    });
  } catch (error) {
    console.error('Error in /register/oauth/google:', error.message);
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
      password: password,
    });
    if (authError) {
      return res.status(401).json({ error: authError.message });
    }

    // Generate JWT
    const token = jwt.sign({ id: authData.user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(200).json({
      'token' : token,
      'userID' : authData.user.id,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Logout
app.post('/logout', verifyToken, async (req, res) => {
  try {
    const token = req.headers['authorization'].split(' ')[1];
    res.status(200).json({ message: 'Logged out' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});



app.get('/profile/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    console.log('ID is: ', id);
    if (!id) {
      return res.status(400).json({ error: 'Missing user ID' });
    }

    // Fetch user from public.users
    const { data: user, error: userError } = await supabase
      .schema('public')
      .from('users')
      .select('id, username')
      .eq('id', id)
      .single();

    if (userError) {
      if (userError.code === 'PGRST116') {
        return res.status(404).json({ error: 'User not found' });
      }
      console.error('Error fetching user:', userError.message);
      return res.status(400).json({ error: userError.message });
    };

    // Fetch user from public.profiles
    const { data: profileInfo, error: profileInfoError } = await supabase
      .schema('public')
      .from('profiles')
      .select()
      .eq('id', id)
      .single();

    if (profileInfoError) {
      if (profileInfoError.code === 'PGRST116') {
        return res.status(404).json({ error: 'User not found' });
      }
      console.error('Error fetching user:', profileInfoError.message);
      return res.status(400).json({ error: profileInfoError.message });
    };

    console.log('\n User data: ', user);
    console.log('\n Profile data: ', profileInfo);


    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json({
      id: user.id,
      username: user.username,
      biography: profileInfo.biography,
      numOfFollowers: profileInfo.numOfFollowers,
      numOfFollowing: profileInfo.numOfFollowing,
      profileImage: profileInfo.profileImage,

    });
  } catch (error) {
    console.error('Error in /profile/:id:', error.message);
    res.status(400).json({ error: error.message });
  }
});

app.put('/profile/:id/bio', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { bio } = req.body;
    console.log(`Updating bio for user: ${id}, bio: ${bio}`);

    if (!bio) {
      return res.status(400).json({ error: 'Missing biography' });
    }

    const { data, error } = await supabase
      .schema('public')
      .from('profiles')
      .update({ biography: bio })
      .eq('id', id)
      // .select()
      // .single();

    if (error) {
      console.error('Error updating bio:', error.message, 'Code:', error.code);
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Profile not found' });
      }
      return res.status(400).json({ error: error.message });
    }

    // res.status(200).json({ message: 'Biography updated', biography: data.biography });
    res.status(200).json({message: 'Biography updated'});
  } catch (error) {
    console.error('Error in /profile/:id/bio:', error.message);
    res.status(400).json({ error: error.message });
  }
});

app.post('/search/users', verifyToken, async (req, res) => {
  try {
    const { query, filter, userID } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'Missing search query' });
    }

    console.log(`Searching users with query: ${query}`);
    const { data: users, error } = await supabase
      .schema('public')
      .from('users')
      .select('id, username')
      .ilike('username', `%${query}%`)
      .limit(20); // Limit to prevent excessive results

    if (error) {
      console.error('Error searching users:', error.message, 'Code:', error.code);
      return res.status(400).json({ error: error.message });
    }

    console.log('Found users:', users);
    res.status(200).json({ users });
  } catch (error) {
    console.error('Error in /search/users:', error.message);
    res.status(400).json({ error: error.message });
  }
});

app.post('/preorder', verifyToken, async (req, res) => {
  try{
    const { user_id } = req.body;
    if (!user_id) {
      return res.status(400).json({error: 'Missing user id'});
    }

    const {data, error} = await supabase
    .schema('public')
    .from('preorders')
    .insert(
      {
        userID: user_id
      }
    )

    if (error) {
      return res.status(400).json({error: error});
    }

    return res.status(200).json({message: 'Preorder created'})
  } catch (error) {
    console.error('Error of create preorder', error.message);
    return res.status(400).json({error: error.message});
  }
})

const PORT = process.env.PORT || 3001; // Fallback for local testing
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});