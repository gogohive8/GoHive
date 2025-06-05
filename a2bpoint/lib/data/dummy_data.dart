import '../models/post.dart';

final List<Post> dummyPosts = [
  Post(
    id: "1",
    user: User(
        id: "user1",
        username: "Mariia",
        avatarUrl: "https://via.placeholder.com/50"),
    imageUrl: "https://via.placeholder.com/300x200",
    text:
        "Went out to the playground today to play with friends. It was a cool afternoon, and we had a blast!",
    createdAt: DateTime(2025, 6, 1),
    likes: 32,
    comments: 234,
  ),
  Post(
    id: "2",
    user: User(
        id: "user2",
        username: "Oscar",
        avatarUrl: "https://via.placeholder.com/50"),
    imageUrl: "https://via.placeholder.com/300x200",
    text: "Ran over the bridge today. Look how big it is!",
    createdAt: DateTime(2025, 6, 2),
    likes: 32,
    comments: 234,
  ),
  Post(
    id: "3",
    user: User(
        id: "user3",
        username: "Dmitry",
        avatarUrl: "https://via.placeholder.com/50"),
    imageUrl: "https://via.placeholder.com/300x200",
    text:
        "We drink smoothies every day together. I suggest all smoothie lovers join us.",
    createdAt: DateTime(2025, 6, 3),
    likes: 32,
    comments: 234,
  ),
];
