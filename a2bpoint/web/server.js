const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from current directory
app.use(express.static(path.join(__dirname)));

// Fallback to index.html or verify-email.html based on path
app.get('/verify-email', (req, res) => {
  res.sendFile(path.join(__dirname, 'verify-email.html'));
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`GoHive redirect landing running on port ${PORT}`);
});
