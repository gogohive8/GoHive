import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../services/post_service.dart';
import '../providers/auth_provider.dart';
import '../screens/post_detail_screen.dart';
import '../screens/challenge_full_screen.dart';
import '../screens/task_detail_screen.dart';
import 'navbar.dart';
import 'dart:developer' as developer;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _selectedTabIndex = 0;
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  late TabController _tabController;
  final Map<String, VideoPlayerController> _videoControllers = {};
  
  // Основные списки данных
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  String? _error;
  
  // Переменные для пагинации
  static const int _postsPerPage = 20;
  int _goalsOffset = 0;
  int _eventsOffset = 0;
  bool _goalsHasMore = true;
  bool _eventsHasMore = true;
  bool _isLoadingMoreGoals = false;
  bool _isLoadingMoreEvents = false;
  
  // Флаги для ленивой загрузки вкладок
  bool _goalsLoaded = false;
  bool _eventsLoaded = false;
  
  // Контроллеры для скролла
  final ScrollController _goalsScrollController = ScrollController();
  final ScrollController _eventsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Настройка слушателей скролла для пагинации
    _goalsScrollController.addListener(_onGoalsScroll);
    _eventsScrollController.addListener(_onEventsScroll);
    
    // Загружаем только Goals при старте (первая вкладка)
    _checkAuthAndLoadInitialTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _goalsScrollController.dispose();
    _eventsScrollController.dispose();
    _videoControllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _checkAuthAndLoadInitialTab() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isInitialized) {
      developer.log('AuthProvider not initialized, waiting for initialization',
          name: 'HomeScreen');
      try {
        await authProvider.initialize();
        if (mounted) {
          _loadTabData(0); // Загружаем первую вкладку (Goals)
        }
      } catch (e) {
        developer.log('Auth initialization error: $e', name: 'HomeScreen');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Authentication failed: $e';
          });
        }
      }
    } else {
      developer.log('AuthProvider initialized, loading initial tab',
          name: 'HomeScreen');
      _loadTabData(0); // Загружаем первую вкладку (Goals)
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      
      // Ленивая загрузка при переключении вкладок
      _loadTabData(_selectedTabIndex);
    }
  }

  void _loadTabData(int tabIndex) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated ||
        authProvider.userId == null ||
        authProvider.token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    switch (tabIndex) {
      case 0: // Goals
        if (!_goalsLoaded) {
          _fetchGoals(authProvider, isInitial: true);
        }
        break;
      case 1: // Events
        if (!_eventsLoaded) {
          _fetchEvents(authProvider, isInitial: true);
        }
        break;
      case 2: // Challenge/Missions
        // Ничего не загружаем, это статический контент
        break;
    }
  }

  void _fetchGoals(AuthProvider authProvider, {bool isInitial = false}) async {
    if (_isLoadingMoreGoals || (!_goalsHasMore && !isInitial)) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
        _error = null;
        _goalsOffset = 0;
        _goalsHasMore = true;
        _goals.clear();
      } else {
        _isLoadingMoreGoals = true;
      }
    });

    try {
      developer.log('Fetching goals offset ${_goalsOffset}', name: 'HomeScreen');
      
      final goals = await _postService.getGoalsPaginated(
        authProvider.token!, 
        authProvider.userId!,
        offset: _goalsOffset,
        limit: _postsPerPage,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _goals = goals;
            _goalsLoaded = true;
            _isLoading = false;
          } else {
            _goals.addAll(goals);
            _isLoadingMoreGoals = false;
          }
          
          _goalsHasMore = goals.length == _postsPerPage;
          _goalsOffset += goals.length;
        });
      }
    } catch (e) {
      developer.log('Fetch goals error: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          if (isInitial) {
            _isLoading = false;
          } else {
            _isLoadingMoreGoals = false;
          }
          _error = e.toString();
        });
      }
    }
  }

  void _fetchEvents(AuthProvider authProvider, {bool isInitial = false}) async {
    if (_isLoadingMoreEvents || (!_eventsHasMore && !isInitial)) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
        _error = null;
        _eventsOffset = 0;
        _eventsHasMore = true;
        _events.clear();
      } else {
        _isLoadingMoreEvents = true;
      }
    });

    try {
      developer.log('Fetching events offset ${_eventsOffset}', name: 'HomeScreen');
      
      final events = await _postService.getEventsPaginated(
        authProvider.token!, 
        authProvider.userId!,
        offset: _eventsOffset,
        limit: _postsPerPage,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _events = events;
            _eventsLoaded = true;
            _isLoading = false;
          } else {
            _events.addAll(events);
            _isLoadingMoreEvents = false;
          }
          
          _eventsHasMore = events.length == _postsPerPage;
          _eventsOffset += events.length;
        });
      }
    } catch (e) {
      developer.log('Fetch events error: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          if (isInitial) {
            _isLoading = false;
          } else {
            _isLoadingMoreEvents = false;
          }
          _error = e.toString();
        });
      }
    }
  }

  void _onGoalsScroll() {
    if (_goalsScrollController.position.pixels >=
        _goalsScrollController.position.maxScrollExtent - 200) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _fetchGoals(authProvider);
    }
  }

  void _onEventsScroll() {
    if (_eventsScrollController.position.pixels >=
        _eventsScrollController.position.maxScrollExtent - 200) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _fetchEvents(authProvider);
    }
  }

  Future<void> _refreshCurrentTab() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (_selectedTabIndex) {
      case 0:
        _goalsLoaded = false;
        _fetchGoals(authProvider, isInitial: true);
        break;
      case 1:
        _eventsLoaded = false;
        _fetchEvents(authProvider, isInitial: true);
        break;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  Widget _buildMediaWidget(Post post) {
    if (post.imageUrls == null || post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    String cleanUrl = post.imageUrls![0];
    if (cleanUrl.startsWith('[') && cleanUrl.endsWith(']')) {
      cleanUrl = cleanUrl.substring(1, cleanUrl.length - 1);
    }
    cleanUrl = cleanUrl.trim();

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      developer.log('Invalid URL format: $cleanUrl', name: 'HomeScreen');
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Invalid image URL', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    developer.log('Loading cleaned media: $cleanUrl', name: 'HomeScreen');

    final isVideo = cleanUrl.toLowerCase().endsWith('.mp4') ||
        cleanUrl.toLowerCase().endsWith('.mov') ||
        cleanUrl.toLowerCase().endsWith('.avi');

    if (isVideo) {
      if (!_videoControllers.containsKey(post.id)) {
        _videoControllers[post.id] =
            VideoPlayerController.networkUrl(Uri.parse(cleanUrl))
              ..initialize().then((_) {
                if (mounted) setState(() {});
              });
      }
      final controller = _videoControllers[post.id]!;
      return controller.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                ),
              ],
            )
          : Container(
              height: 200,
              child: const Center(child: CircularProgressIndicator()),
            );
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        developer.log('Image load error: $error for URL: $cleanUrl',
            name: 'HomeScreen');
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Image not available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
      httpHeaders: const {
        'User-Agent': 'Flutter App',
      },
    );
  }

  Widget _buildMissionsView() {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;
    final aspectRatio = 375 / 790;
    final containerHeight = size.width / aspectRatio;

    return Center(
      child: SizedBox(
        width: size.width * 0.9,
        height: containerHeight * 0.9,
        child: CustomPaint(
          painter: MissionsBackgroundPainter(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildChallengeCard(
                        title: 'The "Tidy Up" Challenge',
                        description:
                            '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/tidy_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Tidy Up" Challenge',
                                subtitle: 'Start cleaning up and stay organized!',
                                headerImageAsset: 'assets/images/tidy_challenge.png',
                                tasks: [
                                  [
                                    TaskItem(id: '1', title: 'Tidy your desk', description: 'Remove clutter, sort everything into its place, and wipe down the surface.'),
                                    TaskItem(id: '2', title: 'Clean your screen and keyboard', description: 'Get rid of fingerprints, crumbs, and dust.'),
                                    TaskItem(id: '3', title: 'Declutter your nightstand', description: 'Keep only the essentials. Store or throw away the rest.'),
                                  ],
                                  [
                                    TaskItem(id: '4', title: 'Do your laundry', description: 'Sort, wash, dry, and fold your clothes.'),
                                    TaskItem(id: '5', title: 'Organize your wardrobe', description: 'Put away anything you no longer wear. Group clothes by type.'),
                                    TaskItem(id: '6', title: 'Sort by season', description: 'Store off-season clothes in boxes or separate shelves.')
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Clear papers from your desk', description: 'Throw away old notes, receipts, and random sheets.'),
                                    TaskItem(id: '7', title: 'Organize important documents', description: 'Create folders like “Important,” “To Sign,” and “Archived.” Scan if needed.'),
                                    TaskItem(id: '7', title: 'Set up a system', description: 'Use trays, binders, or drawers to keep documents under control.')
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Clean the sink and mirror', description: 'Remove buildup and make surfaces sparkle.'),
                                    TaskItem(id: '7', title: 'Check product expiration dates', description: 'Toss anything expired. Keep only what you use.'),
                                    TaskItem(id: '7', title: 'Organize drawers and shelves', description: 'Group items: hygiene, skincare, medicine, etc.')
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Declutter drawers', description: 'Empty, wipe, and only return what\'s truly needed.'),
                                    TaskItem(id: '7', title: 'Clean out your bag or backpack', description: 'Toss old receipts, trash, and unused items.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Declutter your home screen', description: 'Keep only essentials, group apps.'),
                                    TaskItem(id: '7', title: 'Delete photos & videos', description: 'Remove duplicates and old screenshots.'),
                                    TaskItem(id: '7', title: 'Uninstall unused apps', description: 'Free up space and improve speed.'),
                                    TaskItem(id: '7', title: 'Clean up downloads', description: 'Organize or delete random files.'),
                                    TaskItem(id: '7', title: 'Tidy up your inbox', description: 'Unsubscribe, archive, and delete junk.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Vacuum and mop floors', description: 'Finish strong with a clean sweep.'),
                                    TaskItem(id: '7', title: 'Freshen the air', description: 'Open windows or light a candle.'),
                                    TaskItem(id: '7', title: 'Add personal touches', description: 'Decorate with flowers or photos.'),
                                    TaskItem(id: '7', title: 'Wipe handles and switches', description: 'Sanitize the forgotten spots.'),
                                    TaskItem(id: '7', title: 'Celebrate your progress', description: 'Relax and enjoy your tidy space.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Moon" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/moon_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Moon" Challenge',
                                subtitle: 'Start cleaning up and stay organized!',
                                headerImageAsset: 'assets/images/moon_challenge.png',
                                tasks: [
                                  [
                                    TaskItem(id: '7', title: 'Take 10 minutes of silence', description: 'No phone, no talking — just breathe.'),
                                    TaskItem(id: '7', title: 'Stretch your body gently', description: 'Ease into the day with mindful movement.'),
                                    TaskItem(id: '7', title: 'Drink a full glass of water', description: 'Hydrate and refresh your system.'),
                                    TaskItem(id: '7', title: 'Sit by a window for 5 minutes', description: 'Feel the light and the moment.'),
                                    TaskItem(id: '7', title: 'Set one simple intention', description: 'Choose how you want to feel today.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Journal your thoughts', description: 'Write freely for 10 minutes. No filter.'),
                                    TaskItem(id: '7', title: 'Declutter one mental to-do', description: 'Finish or remove something nagging you.'),
                                    TaskItem(id: '7', title: 'Turn off notifications', description: 'Let your mind rest from constant input.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Eat one mindful meal', description: 'No screens, just focus on the taste.'),
                                    TaskItem(id: '7', title: 'Prepare a healthy snack', description: 'Fuel your body with something fresh.'),
                                    TaskItem(id: '7', title: 'Go for a short walk', description: 'Let your body and mind breathe together.'),
                                    TaskItem(id: '7', title: 'Do 5 minutes of deep breathing', description: 'Calm your system with full, slow breaths.'),
                                    TaskItem(id: '7', title: 'Drink herbal tea or warm water', description: 'Soothe your body gently from the inside.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Light a candle or incense', description: 'Create calm with scent and glow.'),
                                    TaskItem(id: '7', title: 'Tidy your sleep area', description: 'Clean sheets, soft light, calm vibes.'),
                                    TaskItem(id: '7', title: 'Put away one pile of clutter', description: 'Just one. That’s enough today.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Watch the moon tonight', description: 'Even for 2 minutes — connect upward.'),
                                    TaskItem(id: '7', title: 'Do a body scan meditation', description: 'Lie down, relax, notice every part.'),
                                    TaskItem(id: '7', title: 'Say no to one extra thing', description: 'Protect your energy. It’s okay.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Write down what you’re letting go', description: 'Then tear it up or burn it.'),
                                    TaskItem(id: '7', title: 'Unfollow one negative account', description: 'Your feed affects your mind.'),
                                    TaskItem(id: '7', title: 'Take a long exhale', description: 'Let your whole body soften with it.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Write down a dream or goal', description: 'Big or small — give it a name.'),
                                    TaskItem(id: '7', title: 'Reflect on this week', description: 'What felt good? What surprised you?'),
                                    TaskItem(id: '7', title: 'Do something that feels magical', description: 'A bath, a tea ritual, stargazing — your choice.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Animal" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/animal_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Animal" Challenge',
                                subtitle: 'Start cleaning up and stay organized!',
                                headerImageAsset: 'assets/images/animal_challenge.png',
                                tasks: [
                                  [
                                    TaskItem(id: '7', title: 'Stretch like a cat', description: 'Do slow, intentional full-body stretches.'),
                                    TaskItem(id: '7', title: 'Nap like a lion', description: 'Take a guilt-free 20-minute rest.'),
                                    TaskItem(id: '7', title: 'Observe like a bird', description: 'Spend 5 minutes just watching the world.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Walk like a fox', description: 'Go for a quiet, mindful walk outdoors.'),
                                    TaskItem(id: '7', title: 'Listen like a deer', description: 'Be still and notice every sound around you.'),
                                    TaskItem(id: '7', title: 'Move lightly', description: 'Practice being gentle in your steps and actions.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Hydrate like a camel', description: 'Drink plenty of water throughout the day.'),
                                    TaskItem(id: '7', title: 'Eat with instinct', description: 'Choose meals based on how your body feels.'),
                                    TaskItem(id: '7', title: 'Pause between bites', description: 'Chew slowly and mindfully.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Declutter like a squirrel', description: 'Sort or store one small pile of clutter.'),
                                    TaskItem(id: '7', title: 'Plan like an ant', description: 'Write down your top 3 priorities for the week.'),
                                    TaskItem(id: '7', title: 'Tidy your “nest”', description: 'Make your home base feel calm and safe.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Defend your space like a bear', description: 'Say “no” to something that drains you.'),
                                    TaskItem(id: '7', title: 'Roar if needed', description: 'Let out your feelings — journal, voice note, or vent.'),
                                    TaskItem(id: '7', title: 'Protect your time', description: 'Turn off distractions for 1 hour.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Connect like wolves', description: 'Message someone you miss or admire.'),
                                    TaskItem(id: '7', title: 'Play like a puppy', description: 'Do something just for fun and joy.'),
                                    TaskItem(id: '7', title: 'Share a kind word', description: 'Lift someone up with a sincere compliment.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Rest like a panda', description: 'Take it slow and release pressure to perform.'),
                                    TaskItem(id: '7', title: 'Be curious like a dolphin', description: 'Learn something new just for fun.'),
                                    TaskItem(id: '7', title: 'Reflect like an owl', description: 'Write down one thing you’ve learned this week.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Dance" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/dance_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Dance" Challenge',
                                subtitle: 'Start cleaning up and stay organized!',
                                headerImageAsset: 'assets/images/dance_challenge.png',
                                tasks: [
                                  [
                                    TaskItem(id: '7', title: 'Do a 1-song freestyle', description: 'Put on any song and move however you like.'),
                                    TaskItem(id: '7', title: 'Move your arms in slow motion', description: 'Feel the air and flow like water.'),
                                    TaskItem(id: '7', title: 'Loosen up your neck and shoulders', description: 'Roll, sway, and release tension.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Dance with your eyes closed', description: 'Let your body lead, not your mind.'),
                                    TaskItem(id: '7', title: 'Follow the rhythm of your breath', description: 'Move slowly, in sync with your inhale and exhale.'),
                                    TaskItem(id: '7', title: 'Sway while standing still', description: 'Even subtle movement is a dance.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Try a cultural dance move', description: 'Look up a step from another culture and give it a go.'),
                                    TaskItem(id: '7', title: 'Use your hands expressively', description: 'Wave, shape, or reach — let hands speak.'),
                                    TaskItem(id: '7', title: 'Bounce to a beat while doing chores', description: 'Turn mundane into fun.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Spin around 5 times', description: 'Feel the dizziness and joy like a child.'),
                                    TaskItem(id: '7', title: 'Improvise with props', description: 'Use a scarf, towel, or bottle in your dance.'),
                                    TaskItem(id: '7', title: 'Dance in front of a mirror', description: 'Notice your flow, not flaws.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Stomp the ground with rhythm', description: 'Feel your power and weight.'),
                                    TaskItem(id: '7', title: 'Clap along with a song', description: 'Add percussion with your body.'),
                                    TaskItem(id: '7', title: 'Step to a beat outdoors', description: 'Bring your groove to the street.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Stretch like a ballerina', description: 'Slow, graceful, and full of poise.'),
                                    TaskItem(id: '7', title: 'Watch a dance performance', description: 'Get inspired by others’ movement.'),
                                    TaskItem(id: '7', title: 'Practice body isolation', description: 'Move only one part: hips, shoulders, chest, etc.'),
                                  ],
                                  [
                                    TaskItem(id: '7', title: 'Dance your mood', description: 'Happy, tired, wild, calm — let it all out.'),
                                    TaskItem(id: '7', title: 'Record a short dance video', description: 'Just for you — or to share.'),
                                    TaskItem(id: '7', title: 'Celebrate your body', description: 'End with a dance of gratitude and self-love.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF666666))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                    image: AssetImage(imageAsset), fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onLikeButtonTapped(String postId, bool isLiked) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like posts')),
        );
      }
      return isLiked;
    }

    try {
      if (!isLiked) {
        await _postService.likePost(postId, userId, token);
        setState(() {
          if (_selectedTabIndex == 0) {
            _goals = _goals.map((post) {
              if (post.id == postId) {
                return post.copyWith(numOfLikes: post.numOfLikes + 1);
              }
              return post;
            }).toList();
          } else if (_selectedTabIndex == 1) {
            _events = _events.map((post) {
              if (post.id == postId) {
                return post.copyWith(numOfLikes: post.numOfLikes + 1);
              }
              return post;
            }).toList();
          }
        });
      }
      return !isLiked;
    } catch (e) {
      developer.log('Like post error: $e', name: 'HomeScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: $e')),
        );
      }
      return isLiked;
    }
  }

  void _joinEvent(String eventId, String eventText) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to join events')),
        );
      }
      return;
    }

    try {
      developer.log('Joining event: eventId=$eventId', name: 'HomeScreen');
      await _postService.joinEvent(
          eventId, authProvider.userId!, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $eventText')),
        );
      }
    } catch (e) {
      developer.log('Join event error: $e', name: 'HomeScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0
                        ? const Color(0xFFAFCBEA)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1
                        ? const Color(0xFFAFCBEA)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _tabController.animateTo(2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Challenge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 2
                        ? const Color(0xFFAFCBEA)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsView(type: 'goal', posts: _goals),
          _buildPostsView(type: 'event', posts: _events),
          _buildMissionsView(),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPostsView({required String type, required List<Post> posts}) {
    final bool isGoals = type == 'goal';
    final ScrollController scrollController = isGoals ? _goalsScrollController : _eventsScrollController;
    final bool isLoadingMore = isGoals ? _isLoadingMoreGoals : _isLoadingMoreEvents;
    final bool hasMore = isGoals ? _goalsHasMore : _eventsHasMore;
    final bool isTabLoaded = isGoals ? _goalsLoaded : _eventsLoaded;

    if (!isTabLoaded && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading $type',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshCurrentTab,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAFCBEA),
                foregroundColor: const Color(0xFF000000),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty && isTabLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $type to display',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a ${type.toLowerCase()}!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: posts.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return hasMore 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
          }

          final post = posts[index];
          return Card(
            color: const Color(0xFFDDDDDD),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetailScreen(postId: post.id, postType: type),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: post.user.profileImage.isNotEmpty
                              ? NetworkImage(post.user.profileImage)
                              : null,
                          backgroundColor: const Color(0xFF333333),
                          radius: 20,
                          child: post.user.profileImage.isEmpty
                              ? Text(
                                  post.user.username.isNotEmpty
                                      ? post.user.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.user.username.isNotEmpty
                                    ? post.user.username
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMediaWidget(post),
                    const SizedBox(height: 12),
                    Text(
                      post.text ?? 'No description',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (type == 'goal' &&
                        post.tasks != null &&
                        post.tasks!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      ...post.tasks!.map((task) => Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 12,
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${post.numOfLikes} likes',
                              style: const TextStyle(color: Color(0xFF000000)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${post.numComments} comments',
                              style: const TextStyle(color: Color(0xFF000000)),
                            ),
                          ],
                        ),
                        if (type == 'goal')
                          LikeButton(
                            onTap: (isLiked) =>
                                _onLikeButtonTapped(post.id, isLiked),
                            size: 25,
                            circleColor: const CircleColor(
                                start: Color(0xffFFC0CB),
                                end: Color(0xffff0000)),
                            bubblesColor: const BubblesColor(
                              dotPrimaryColor: Color(0xffFFA500),
                              dotSecondaryColor: Color(0xffd8392b),
                              dotThirdColor: Color(0xffFF69B4),
                              dotLastColor: Color(0xffff8c00),
                            ),
                            likeBuilder: (isLiked) {
                              return Icon(
                                isLiked
                                    ? Ionicons.heart
                                    : Ionicons.heart_outline,
                                color: isLiked
                                    ? Colors.red
                                    : const Color(0xFF333333),
                                size: 25,
                              );
                            },
                          )
                        else
                          ElevatedButton(
                            onPressed: () =>
                                _joinEvent(post.id, post.text ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAFCBEA),
                              foregroundColor: const Color(0xFF000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Join'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MissionsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4F3EE);
    final radius = 32.0;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}


