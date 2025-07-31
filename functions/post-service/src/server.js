const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { error } = require('console');

require('dotenv').config({ path: __dirname + '/../.env'});


const app = express();

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
      return res.status(400).json( {error: insertGoalError} );
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
      return res.status(400).json( { error: insertStepsError });
    }

    if (image_urls){
    const { error: insertPhotoError } = await supabase
    .schema('posts')
    .from('goalsPhotos')
    .insert({
      goalId: goalInfo.id,
      photoURL: image_urls || [],
    });

    if ( insertPhotoError ) {
      console.error('Error of insert photo url', insertPhotoError);
      res.status(400).json({ error: insertPhotoError });
    }
  };

    return res.status(200).json({ message: 'Goals created successfully'});

  } catch (error) {
    console.error('Error on create goals: ', error.message);
  }
});

app.post('/events/create',verifyToken, async (req, res) => {
  try{
    const { user_id, description, location, date_time, image_urls } = req.body;

    const { data: eventInfo, error: insertEventError } = await supabase
    .schema('posts')
    .from('events')
    .insert({
      userID: user_id,
      description: description,
      location: location,
      date_time: date_time,
    })
    .select('id')
    .single();

    console.log('\neventsInfo', eventInfo);
    if (insertEventError) {
      console.error('Error by insert goal info: ', insertEventError);
      return res.status(400).json( {error: insertGoalError} );
    };


    if (image_urls){
    const { error: insertPhotoError } = await supabase
    .schema('posts')
    .from('eventsPhotos')
    .insert({
      eventID: eventInfo.id,
      photoURL: image_urls || '',
    });


    if ( insertPhotoError ) {
      console.error('Error of insert photo url', insertPhotoError);
      res.status(400).json({ error: insertPhotoError });
    }
  };
    return res.status(200).json({ message: 'Event created successfully'});

  } catch (error) {
    console.error('Error on create events: ', error.message);
  }
});



app.get('/goals/all', verifyToken, async (req, res) => {
  try{
    const user_id = req.userId;

    const { data: goals, error: fetchError} = await supabase
    .schema('posts')
    .from('goals')
    .select('id, userID, goalInfo, numOfLikes, numOfComments, created_at')
    .limit(100)

    if (fetchError) {
      console.error('Problem with take data from database', fetchError.message);
      return res.status(400).json({ error : fetchError.message });
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
          return { ...goal, username: "" }; // Fallback to null if user not found
        }
        
        var likedCurrentGoal = false;

        // Fetch liked that post or not
        const {data: likedGoal, error: fetchLikeError } = await supabase
        .schema('posts')
        .from('likedGoals')
        .select('*')
        .match({userID: user_id, goalID: goal.id})
        .single()

        if (fetchLikeError) {
          console.error(`Error fetching like for goal ${goal.id}:`, fetchLikeError.message);
        } else if (likedGoal) {
          likedCurrentGoal = true;
        }


        const {data: imageURL, error: fetchUrlError} = await supabase
        .schema('posts')
        .from('goalsPhotos')
        .select('photoURL')
        .eq('goalId', goal.id)

        if (fetchUrlError) {
          console.error('Error of fetch urls', fetchUrlError);
          return {...goal, image_urls: []}
        }

        // Map photoURLs to an array
        const photoURLs = imageURL ? imageURL.map(item => item.photoURL) : [];

        // Replace userID with username
        return {
          id: goal.id,
          username: user.username,
          userID: goal.userID,
          goalInfo: goal.goalInfo,
          numOfLikes: goal.numOfLikes,
          numOfComments: goal.numOfComments,
          likedCurrentGoal: likedCurrentGoal,
          created_at: goal.created_at,
          image_urls: photoURLs,
        };
      })
    );

    console.log('\nData is: ', goalsWithUsername);
    return res.status(200).json(goalsWithUsername);

  } catch (error){
    console.error('Error by fetching goals');
    return res.status(400).json({ error: error.message });
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
      return res.status(400).json({ error : fetchError.message });
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

        const {data: imageURL, error: fetchUrlError} = await supabase
        .schema('posts')
        .from('eventsPhotos')
        .select('photoURL')
        .eq('eventID', event.id)

        if (fetchUrlError) {
          console.error('Error of fetch urls', fetchUrlError);
          return {...goal, image_urls: []}
        }

        // Map photoURLs to an array
        const photoURLs = imageURL ? imageURL.map(item => item.photoURL) : [];


        // Replace userID with username
        return {
          id: event.id,
          username: event ? user.username : null,
          description: event.description,
          numOfLikes: event.numOfLikes,
          numOfComments: event.numOfComments,
          image_urls: photoURLs,
        };
      })
    );

    console.log('\nData is: ', eventsWithUsername);
    return res.status(200).json(eventsWithUsername);

  } catch (error){
    console.error('Error by fetching events');
    return res.status(400).json({ error: error.message });
  }
});


app.get('/goals/:id', verifyToken,  async (req, res) => {
  try{
    const { id } = req.params;
    console.log('ID is: ', id);
    if (!id) {
      return res.status(400).json({ error: 'Missing user ID' });
    }

    const { data: goals, error: fetchError} = await supabase
    .schema('posts')
    .from('goals')
    .select('*')
    .eq('userID', id)
    if (fetchError) {
      console.error('Error of fetching: ', fetchError.message);
      res.status(400).json({ error: fetchError.message });
    }

    if (!goals || goals.length === 0) {
      console.log('No goals found for user:', id);
      return res.status(200).json([]);
    }


    const userGoalsPhotos = await Promise.all(
      goals.map(async (goal) => {
        const {data: photo, error: photoFetchError } = await supabase
        .schema('posts')
        .from('goalsPhotos')
        .select('photoUrl')
        .eq('goalId', goal.id)

        if (fetchError) {
          console.error('Error with fetching photo url', fetchError.message);
          return {
          userID: id,
          description: goal.goalInfo,
          created_at: goal.created_at,
          numOfLikes: goal.numOfLikes,
          numOfComments: goal.numOfComments,
          id: goal.id,
          photoURL: '',
          }
        }


        return {
          userID: id,
          description: goal.goalInfo,
          created_at: goal.created_at,
          numOfLikes: goal.numOfLikes,
          numOfComments: goal.numOfComments,
          id: goal.id,
          photoURL: photo?.photoURL || '',
        };
      }) 
    );

    console.log('photos url: ', userGoalsPhotos);
    return res.status(200).json(userGoalsPhotos);
  } catch (error) {
    console.error('Error of fetching photos url: ', error.message);
    return res.status(400).json({error: error.message});
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
    .select('*')
    .eq('userID', id)

    if (fetchError) {
      console.error('Error of fetching: ', fetchError.message);
      return res.status(400).json({ error: fetchError.message });
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
          return {
          userID: id,
          description: event.description,
          created_at: event.created_at,
          numOfLikes: event.numOfLikes,
          numOfComments: event.numOfComments,
          id: event.id,
          photoURL: '',
          };
        }


        return {
          userID: id,
          description: event.description,
          created_at: event.created_at,
          numOfLikes: event.numOfLikes,
          numOfComments: event.numOfComments,
          id: event.id,
          photoURL: photo?.photoURL || '',
        };
      }) 
    );

    console.log('photos url: ', userEventsPhotos);
    return res.status(200).json(userEventsPhotos);
  } catch (error) {
    console.error('Error of fetching photos url: ', error.message);
    return res.status(400).json({error: error.message});
  }
});

app.post('/like', verifyToken,  async (req, res) => {
  try{
    const { post_id, user_id } = req.body;

    const {data: getLike, error: getLikeError} = await supabase
    .schema('posts')
    .from('goals')
    .select('id, numOfLikes')
    .eq('id', post_id)
    .single()

    if (getLikeError) {
      console.error('Error of fetch num of likes: ', getLikeError.message);
      return res.status(400).json({ error: getLikeError.message})
    }

    const likes = getLike.numOfLikes + 1;

    const {data: insertLike, error: updateError} = await supabase
    .schema('posts')
    .from('goals')
    .update({ numOfLikes: likes })
    .eq('id', post_id)

    if (updateError) {
      console.error('Error of update num of likes: ', updateErrorError.message);
      res.status(400).json({ error: updateErrorError.message})
    }

    const {error: userLikeError} = await supabase
    .schema('posts')
    .from('likedGoals')
    .insert(
      {
        userID: user_id,
        goalID: post_id
      }
    )

    if (userLikeError) {
      console.error('Error of insert user like information: ', userLikeError);
      res.status(400).json({ error: userLikeError.message})
    }

    return res.status(200).json({message: 'Like update successfully'});

  } catch (error) {
    console.error('Error of like: ', error.message);
    return res.status(400).json({error: error.message});
  }
})


app.post('/joinEvent', verifyToken, async(req, res) => {
  try{

    const { post_id, user_id } = req.body;

    const {error: userJoinError} = await supabase
    .schema('posts')
    .from('joinedEvent')
    .insert(
      {
        eventID: post_id,
        userID: user_id
      }
    )

    if (userJoinError) {
      console.error('Error of insert user like information: ', userJoinError);
      res.status(400).json({ error: userJoinError.message})
    }

    return res.status(200).json({message: 'Like update successfully'});

  } catch (joinError) {
    console.error('Error of join event: ', joinError);
    return res.status(400).json({error: joinError});
  }
})

app.post('/upload', upload.array('files', 10), async (req, res) => {
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
    // return res.status(200).json(photoUrls);
    return res.status(200).json(photoUrls.length === 1 ? { url: photoUrls[0] } : photoUrls);
  } catch (error) {
    console.error('Error in /upload:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});


app.get('/posts/:post_id', verifyToken, async (req, res) => {
  try{
    const {post_id} = req.params;

    const {data: post, error: fetchGoalError} = await supabase
    .schema('posts')
    .from('goals')
    .select('*')
    .eq('id', post_id)
    .single()
    
    if (fetchGoalError) {
      console.error('Error of fetch goal', fetchGoalError);
      return res.status(400).json({error: fetchGoalError});
    }

    const {data: goalTasks, error: fetchStepsError} = await supabase
    .schema('posts')
    .from('steps')
    .select('*')
    .eq('goalID', post_id)
    .single()

    if (fetchStepsError) {
      console.error('Error of fetch steps', fetchStepsError);
    }

    const {data: goalsPhotos, error: fetchPhotosError} = await supabase
    .schema('posts')
    .from('goalsPhotos')
    .select('photoURL')
    .eq('goalId', post_id)

    if (fetchPhotosError) {
      console.error('Error of fetch photos', fetchPhotosError);
    }

    const {data: username, error: fetchUsernameError} = await supabase
    .schema('public')
    .from('users')
    .select('username')
    .eq('id', post.userID)
    .single()

    if(fetchUsernameError){
      console.error('Error of fetch username', fetchUsernameError);
    }

    // Parse tasks if stored as a JSON string or array of strings
    let tasks = [];
    if (goalTasks.stepsInfo) {
      try {
        if (typeof post.tasks === 'string') {
          tasks = JSON.parse(post.tasks);
        } else if (Array.isArray(post.tasks)) {
          tasks = post.tasks.map(task => typeof task === 'string' ? JSON.parse(task) : task);
        }
      } catch (parseError) {
        console.error(`Error parsing tasks for post ${postId}:`, parseError.message);
        tasks = [];
      }
    }

    return res.status(200).json({
      type: 'goal',
      userID: post.userID || '',
      username: username.username || '',
      description: post.goalInfo || '',
      created_at: post.created_at || '',
      tasks: goalTasks.stepsInfo || [],
      numOfLikes: post.numOfLikes || 0,
      numOfComments: post.numOfComments || 0,
      id: post_id || ''
    })
  } catch (fetchPostError){
    console.error('Fetch post error', fetchPostError)
    return res.status(400).json({error: fetchPostError})
  }
})


app.post('/posts/:post_id/comments', verifyToken, async (req, res) => {
  try{
    const {text, userId, postId, post_type} = req.body;

    if (post_type == 'goal'){
      const {error: goalCommentsInsertError} = await supabase
      .schema('posts')
      .from('goalsComments')
      .insert(
        {
          userID: userId,
          goalID: postId,
          comment: text
        }
      ).single()

      if (goalCommentsInsertError) {
        console.error('Problem to insert comment to goal', goalCommentsInsertError);
        return res.status(400).json({error: goalCommentsInsertError});
      }

      console.log('Goal comments created')
      return res.status(200).json({message: 'Complete to create comment to goal'})
    }

    else if (post_type == 'event') {
      const {error: eventCommentsInsertError} = await supabase
      .schema('posts')
      .from('eventsComments')
      .insert({
        userID: userId,
        eventsID: postId,
        comments: text
      }).single();

      if (eventCommentsInsertError) {
        console.error('Problem to insert comment to goal', eventCommentsInsertError);
        return res.status(400).json({error: eventCommentsInsertError});
      }
      
      console.log('Event comments created');
      return res.status(200).json({message: 'Complete to create comment to event'});
    }

    else {
      console.error('Undefined type of post');
      return res.status(400).json({message: 'Undefined type of post'});
    }

  } catch (commentError) {
    console.error('Error of create comments', commentError);
    return res.status(500).json({error: commentError.message});
  } 
})

app.get('/posts/:post_id/comments', verifyToken, async (req, res) => {
  try{
    const {post_id} = req.params;
    const limit = parseInt(req.query.limit) || 10;
    const offset = parseInt(req.query.offset) || 0;
    const post_type = req.query.post_type;

    if (post_type == 'goal'){
      const {data: fetchComments, error: goalCommentsSelectError} = await supabase
      .schema('posts')
      .from('goalsComments')
      .select('*')
      .eq('goalID', post_id);

      
      if (goalCommentsSelectError) {
        console.error('Problem to insert comment to goal', goalCommentsSelectError);
        return res.status(400).json({error: goalCommentsSelectError});
      }

      if (!fetchComments || fetchComments.length === 0) {
        console.log('No comments found');
        return res.status(200).json([]);
    }

      console.log('Goal comments fetched')
      return res.status(200).json({fetchComments})
    }

    else if (post_type == 'event') {
      const {data: fetchComments, error: eventCommentsSelectError} = await supabase
      .schema('posts')
      .from('eventsComments')
      .select('*')
      .eq('eventsID', post_id);

      
      if (eventCommentsSelectError) {
        console.error('Problem to insert comment to goal', eventCommentsSelectError);
        return res.status(400).json({error: eventCommentsSelectError});
      }

      if (!fetchComments || fetchComments.length === 0) {
        console.log('No comments found');
        return res.status(200).json([]);
    }

      console.log('Event comments fetched')
      return res.status(200).json({fetchComments})
    }

    else {
      console.error('Undefined type of post');
      return res.status(400).json({message: 'Undefined type of post'});
    }

  } catch (fetchCommentError) {
    console.error('Error of fetching comments', fetchCommentError);
    return res.status(400).json({error: fetchCommentError});
  }
})


const PORT = process.env.PORT || 3002; // Fallback for local testing
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});