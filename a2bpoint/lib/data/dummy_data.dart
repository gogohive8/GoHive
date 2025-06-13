import '../models/post.dart';
import 'package:intl/intl.dart';

// Dummy Posts
final List<Post> dummyPosts = [
  Post(
    id: '1',
    user: User(
        id: 'user1',
        username: 'Dostoyevsky',
        avatarUrl: 'https://via.placeholder.com/50'),
    imageUrl: 'https://via.placeholder.com/300x200',
    text: 'Goal: Reading "Looking at the Stars" welcome fall!',
    likes: 32,
    comments: 234,
    createdAt: DateTime.now(),
  ),
  Post(
    id: '2',
    user: User(
        id: 'user2',
        username: 'Oscar',
        avatarUrl: 'https://via.placeholder.com/50'),
    imageUrl: 'https://via.placeholder.com/300x200',
    text: 'Ran over that bridge today. Look how big it is!',
    likes: 32,
    comments: 234,
    createdAt: DateTime.now(),
  ),
  Post(
    id: '3',
    user: User(
        id: 'user3',
        username: 'Maria',
        avatarUrl: 'https://via.placeholder.com/50'),
    imageUrl: 'https://via.placeholder.com/300x200',
    text:
        'I suggest all the creative guys who love photography meet up at Tokyo',
    likes: 32,
    comments: 234,
    createdAt: DateTime.now(),
  ),
  Post(
    id: '4',
    user: User(
        id: 'user4',
        username: 'Dmitry',
        avatarUrl: 'https://via.placeholder.com/50'),
    imageUrl: 'https://via.placeholder.com/300x200',
    text:
        'We drink smoothies every day! I suggest that smoothie lovers get together and drink and drink smoothies every day!',
    likes: 32,
    comments: 234,
    createdAt: DateTime.now(),
  ),
];

// Dummy Goals
final List<Map<String, dynamic>> dummyGoals = [
  {
    'id': 'goal1',
    'title': 'Goal 1',
    'description': 'Run over that bridge today. Look how big it is!',
    'avatarUrl': 'https://via.placeholder.com/50',
  },
  {
    'id': 'goal2',
    'title': 'Goal 2',
    'description': 'Reading "Looking at the Stars" welcome fall!',
    'avatarUrl': 'https://via.placeholder.com/50',
  },
];

// Dummy Events
final List<Map<String, dynamic>> dummyEvents = [
  {
    'id': 'event1',
    'title': 'Event 1',
    'description':
        'I suggest all the creative guys who love photography meet up at Tokyo',
    'avatarUrl': 'https://via.placeholder.com/50',
  },
  {
    'id': 'event2',
    'title': 'Event 2',
    'description':
        'We drink smoothies every day! I suggest that smoothie lovers get together and drink and drink smoothies every day!',
    'avatarUrl': 'https://via.placeholder.com/50',
  },
];
