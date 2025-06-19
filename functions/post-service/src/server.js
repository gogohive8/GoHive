const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

require('dotenv').config({ path: __dirname + '/../.env'});

const app = express();
app.use(cors({
  origin: 'http://gohive-d4359.web.app', // Replace with your Flutter web app's URL
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
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


// Configure multer for multiple photo uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 5MB per file
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) {
      return cb(new Error('Only images are allowed'));
    }
    cb(null, true);
  },
});


app.post('/goals/create', verifyToken, async (req, res) => {
  try{
    const { user_id, description, location, interest, point_a, point_b, tasks, image_urls } = req.body;

    const { data: goalInfo, error: insertGoalError } = await supabase
    .schema('posts')
    .from('goals')
    .insert({
      userID: user_id,
      category: interest,
      pointA: point_a,
      pointB: point_b,
      goalInfo: description,
      location: location,
    })
    .select('id')
    .single();

    console.log('\ngoalsInfo', goalInfo);
    if (insertGoalError) {
      console.error('Error by insert goal info: ', insertGoalError);
      res.status(400).json( {error: insertGoalError} );
    };

    const { error: insertStepsError } = await supabase
    .schema('posts')
    .from('steps')
    .insert({
      goalID: goalInfo.id,
      stepsInfo: tasks,
    });

    if ( insertStepsError ) {
      console.error('Error of insert steps: ', insertStepsError.message);
      res.status(400).json( { error: insertStepsError });
    }

    if (image_urls){
    const { error: insertPhotoError } = await supabase
    .schema('posts')
    .from('goalsPhoto')
    .insert({
      goalsId: goalInfo.id,
      photoURL: image_urls || '',
    });

    if ( insertPhotoError ) {
      console.error('Error of insert photo url', insertPhotoError);
      res.status(400).json({ error: insertPhotoError });
    }
  };

    res.status(200);

  } catch (error) {
    console.error('Error on create goals: ', error.message);
  }
});

app.post('/events/create', verifyToken, async (req, res) => {
  try{
    const { user_id, description, location, interest, date_time, image_urls } = req.body;

    const { data: eventInfo, error: insertEventError } = await supabase
    .schema('posts')
    .from('events')
    .insert({
      userID: user_id,
      category: interest,
      description: description,
      location: location,
    })
    .select('id')
    .single();

    console.log('\neventsInfo', eventInfo);
    if (insertEventError) {
      console.error('Error by insert goal info: ', insertEventError);
      res.status(400).json( {error: insertGoalError} );
    };


    if (image_urls){
    const { error: insertPhotoError } = await supabase
    .schema('posts')
    .from('eventsPhoto')
    .insert({
      eventID: eventInfo.id,
      photoURL: image_urls || '',
    });


    if ( insertPhotoError ) {
      console.error('Error of insert photo url', insertPhotoError);
      res.status(400).json({ error: insertPhotoError });
    }
  };
    res.status(200);

  } catch (error) {
    console.error('Error on create events: ', error.message);
  }
});



app.get('/goals/all', verifyToken, async (req, res) => {
  try{
    const { data: goals, error: fetchError} = await supabase
    .schema('posts')
    .from('goals')
    .select('id, userID, goalInfo, numOfLikes, numOfComments')
    .limit(100)

    if (fetchError) {
      console.error('Problem with take data from database', fetchError.message);
      res.status(400).json({ error : fetchError.message });
    }

    const goalsWithUsername = await Promise.all(
      goals.map(async (goal) => {
        // Fetch username for each userID
        const { data: user, error: fetchUserError } = await supabase
          .schema('public')
          .from('users')
          .select('username')
          .eq('id', goal.userID)
          .single();

        if (fetchUserError) {
          console.error(`Error fetching username for userID ${goal.userID}:`, fetchUserError.message);
          return { ...goal, username: null }; // Fallback to null if user not found
        }

        // Replace userID with username
        return {
          id: goal.id,
          username: user ? user.username : null,
          goalInfo: goal.goalInfo,
          numOfLikes: goal.numOfLikes,
          numOfComments: goal.numOfComments,
        };
      })
    );

    console.log('\nData is: ', goalsWithUsername);
    res.json(goalsWithUsername);

  } catch (error){
    console.error('Error by fetching goals');
    res.status(400).json({ error: error.message });
  }
});

app.get('/events/all', verifyToken, async (req, res) => {
  try{
    const { data: events, error: fetchError} = await supabase
    .schema('posts')
    .from('events')
    .select('id, userID, description, numOfLikes, numOfComments')
    .limit(100)

    if (fetchError) {
      console.error('Problem with take data from database', fetchError.message);
      res.status(400).json({ error : fetchError.message });
    }

    const eventsWithUsername = await Promise.all(
      events.map(async (event) => {
        // Fetch username for each userID
        const { data: user, error: fetchUserError } = await supabase
          .schema('public')
          .from('users')
          .select('username')
          .eq('id', event.userID)
          .single();

        if (fetchUserError) {
          console.error(`Error fetching username for userID ${event.userID}:`, fetchUserError.message);
          return { ...event, username: null }; // Fallback to null if user not found
        }

        // Replace userID with username
        return {
          id: event.id,
          username: event ? user.username : null,
          description: event.description,
          numOfLikes: event.numOfLikes,
          numOfComments: event.numOfComments,
        };
      })
    );

    console.log('\nData is: ', eventsWithUsername);
    res.status(200).json(eventsWithUsername);

  } catch (error){
    console.error('Error by fetching events');
    res.status(400).json({ error: error.message });
  }
});


app.get('/goals/:id', verifyToken, async (req, res) => {
  try{
    const { id } = req.params;
    console.log('ID is: ', id);
    if (!id) {
      return res.status(400).json({ error: 'Missing user ID' });
    }

    const { data: usersGoals, error: fetchError } = await supabase
    .schema('posts')
    .from('goals')
    .select('id')
    .eq('userID', id)

    if (fetchError) {
      console.error('Error of fetching: ', fetchError.message);
      res.status(400).json({ error: fetchError.message });
    }

    if (!usersGoals || usersGoals.length === 0) {
      console.log('No goals found for user:', id);
      return res.status(200).json([]);
    }


    const userGoalsPhotos = await Promise.all(
      usersGoals.map(async (goal) => {
        const {data: photo, error: photoFetchError } = await supabase
        .schema('posts')
        .from('goalsPhotos')
        .select('photoUrl')
        .eq('goalId', goal.id)

        if (fetchError) {
          console.error('Error with fetching photo url', fetchError.message);
          res.status(400).json({error: photoFetchError.message});
        }

        return {
          id: goal.id,
          photoURL: photo.photoURL,
        };
      }) 
    );

    console.log('photos url: ', userGoalsPhotos);
    res.status(200).json(userGoalsPhotos);
  } catch (error) {
    console.error('Error of fetching photos url: ', error.message);
    res.status(400).json({error: error.message});
  }
})

app.get('/events/:id', verifyToken, async (req, res) => {
  try{
        const { id } = req.params;
    console.log('ID is: ', id);
    if (!id) {
      return res.status(400).json({ error: 'Missing user ID' });
    }

    const { data: usersEvents, error: fetchError } = await supabase
    .schema('posts')
    .from('events')
    .select('id')
    .eq('userID', id)

    if (fetchError) {
      console.error('Error of fetching: ', fetchError.message);
      res.status(400).json({ error: fetchError.message });
    }

    if (!usersEvents || usersEvents.length === 0) {
      console.log('No goals found for user:', id);
      return res.status(200).json([]);
    }
    
    const userEventsPhotos = await Promise.all(
      usersEvents.map(async (event) => {
        const {data: photo, error: photoFetchError } = await supabase
        .schema('posts')
        .from('eventsPhotos')
        .select('photoUrl')
        .eq('eventId', event.id)

        if (fetchError) {
          console.error('Error with fetching photo url', fetchError.message);
          res.status(400).json({error: photoFetchError.message});
        }

        return {
          id: event.id,
          photoURL: photo.photoURL,
        };
      }) 
    );

    console.log('photos url: ', userEventsPhotos);
    res.status(200).json(userEventsPhotos);
  } catch (error) {
    console.error('Error of fetching photos url: ', error.message);
    res.status(400).json({error: error.message});
  }
});


app.post('/upload', upload.array('images', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No images provided' });
    }

    const photoUrls = [];
    for (const file of req.files) {
      const fileExt = path.extname(file.originalname).toLowerCase();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}${fileExt}`;

      const { data: uploadData, error: uploadError } = await supabase
        .storage
        .from('avatars')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: true,
        });

      if (uploadError) {
        console.error(`Error uploading image ${fileName}:`, uploadError.message);
        return res.status(500).json({ error: `Failed to upload image ${fileName}` });
      }

      const { data: { publicUrl } } = supabase
        .storage
        .from('avatars')
        .getPublicUrl(fileName);

      photoUrls.push(publicUrl);
    }

    console.log('Images uploaded:', photoUrls);
    return res.status(200).json(photoUrls);
  } catch (error) {
    console.error('Error in /upload:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

const PORT = process.env.PORT || 3002; // Fallback for local testing
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});