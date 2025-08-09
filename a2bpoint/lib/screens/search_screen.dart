import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import 'navbar.dart';
import '../services/exceptions.dart';
import 'Home/post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  // Results for different categories
  List<Post> _goalResults = [];
  List<Post> _eventResults = [];
  List<Map<String, dynamic>> _challengeResults = [];
  List<Map<String, dynamic>> _userResults = [];
  
  bool _isLoading = false;
  Timer? _debounce;
  int _currentTabIndex = 0;
  
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();

  // Predefined challenges (since they are static)
  final List<Map<String, dynamic>> _allChallenges = [
    {
      'id': '1',
      'title': 'The "Tidy Up" Challenge',
      'description': '7-day live challenge\nfor those who are tired',
      'imageAsset': 'assets/images/tidy_challenge.png',
      'keywords': ['tidy', 'clean', 'organize', 'declutter', 'order'],
    },
    {
      'id': '2', 
      'title': 'The "Moon" Challenge',
      'description': '7-day live challenge\nfor mindfulness',
      'imageAsset': 'assets/images/moon_challenge.png',
      'keywords': ['moon', 'mindful', 'meditation', 'calm', 'peace', 'relax'],
    },
    {
      'id': '3',
      'title': 'The "Animal" Challenge', 
      'description': '7-day live challenge\nfor natural movement',
      'imageAsset': 'assets/images/animal_challenge.png',
      'keywords': ['animal', 'movement', 'nature', 'instinct', 'body'],
    },
    {
      'id': '4',
      'title': 'The "Dance" Challenge',
      'description': '7-day live challenge\nfor creative expression', 
      'imageAsset': 'assets/images/dance_challenge.png',
      'keywords': ['dance', 'move', 'rhythm', 'music', 'expression', 'flow'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isInitialized) {
      authProvider.initialize().then((_) {
        _searchController.addListener(_onSearchChanged);
      });
    } else {
      _searchController.addListener(_onSearchChanged);
    }
  }
  
  void _onTabChanged() {
    if (_tabController.index != _currentTabIndex) {
      final previousTab = _currentTabIndex;
      _currentTabIndex = _tabController.index;
      
      developer.log('Tab changed from $previousTab to $_currentTabIndex', name: 'SearchScreen');
      
      // If there's text in search and we changed tabs, perform search for current tab
      // But only if we're not currently loading
      if (_searchController.text.isNotEmpty && !_isLoading) {
        // Cancel any pending debounce
        _debounce?.cancel();
        _performSearch();
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (_searchController.text.isNotEmpty) {
          _performSearch();
        } else {
          setState(() {
            _goalResults = [];
            _eventResults = [];
            _challengeResults = [];
            _userResults = [];
          });
        }
      }
    });
  }

  // Helper function to get interest from Post
  String _getPostInterest(Post post) {
    if (post.additionalData != null && post.additionalData!.containsKey('interest')) {
      return post.additionalData!['interest']?.toString() ?? '';
    }
    return '';
  }

  // Helper function to get location from Post
  String _getPostLocation(Post post) {
    if (post.additionalData != null && post.additionalData!.containsKey('location')) {
      return post.additionalData!['location']?.toString() ?? '';
    }
    return '';
  }

  // Helper function to get pointA from Post
  String _getPostPointA(Post post) {
    if (post.additionalData != null && post.additionalData!.containsKey('pointA')) {
      return post.additionalData!['pointA']?.toString() ?? '';
    }
    return '';
  }

  // Helper function to get pointB from Post
  String _getPostPointB(Post post) {
    if (post.additionalData != null && post.additionalData!.containsKey('pointB')) {
      return post.additionalData!['pointB']?.toString() ?? '';
    }
    return '';
  }

  // Helper function to get dateTime from Post
  String _getPostDateTime(Post post) {
    if (post.additionalData != null && post.additionalData!.containsKey('dateTime')) {
      return post.additionalData!['dateTime']?.toString() ?? '';
    }
    return post.createdAt.toIso8601String();
  }

  Future<List<Post>> _searchGoals(String query, String token, String userId) async {
    try {
      developer.log('Starting goals search with query: "$query"', name: 'SearchScreen');
      
      // Add timeout and better error handling
      final goals = await _postService.getGoalsPaginated(
        token, 
        userId, 
        offset: 0, 
        limit: 50 // Reduce limit to avoid timeouts
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          developer.log('Goals search timed out', name: 'SearchScreen');
          return <Post>[];
        },
      );
      
      developer.log('Retrieved ${goals.length} goals from service', name: 'SearchScreen');
      
      if (goals.isEmpty) {
        return [];
      }
      
      final filteredGoals = goals.where((goal) {
        final text = (goal.text ?? '').toLowerCase();
        final interest = _getPostInterest(goal).toLowerCase();
        final location = _getPostLocation(goal).toLowerCase();
        final pointA = _getPostPointA(goal).toLowerCase();
        final pointB = _getPostPointB(goal).toLowerCase();
        
        final matches = text.contains(query) || 
               interest.contains(query) || 
               location.contains(query) ||
               pointA.contains(query) ||
               pointB.contains(query);
               
        if (matches) {
          developer.log('Goal matches query: "${goal.text}"', name: 'SearchScreen');
        }
        
        return matches;
      }).toList();
      
      developer.log('Filtered goals count: ${filteredGoals.length}', name: 'SearchScreen');
      return filteredGoals;
      
    } catch (e, stackTrace) {
      developer.log('Search goals error: $e', name: 'SearchScreen', stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Post>> _searchEvents(String query, String token, String userId) async {
    try {
      developer.log('Starting events search with query: "$query"', name: 'SearchScreen');
      
      // Add timeout and better error handling
      final events = await _postService.getEventsPaginated(
        token, 
        userId, 
        offset: 0, 
        limit: 50 // Reduce limit to avoid timeouts
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          developer.log('Events search timed out', name: 'SearchScreen');
          return <Post>[];
        },
      );
      
      developer.log('Retrieved ${events.length} events from service', name: 'SearchScreen');
      
      if (events.isEmpty) {
        developer.log('No events found from service', name: 'SearchScreen');
        return [];
      }
      
      // Debug first event data
      if (events.isNotEmpty) {
        final firstEvent = events.first;
        developer.log('First event data:', name: 'SearchScreen');
        developer.log('  - text: "${firstEvent.text}"', name: 'SearchScreen');
        developer.log('  - interest: "${_getPostInterest(firstEvent)}"', name: 'SearchScreen');
        developer.log('  - location: "${_getPostLocation(firstEvent)}"', name: 'SearchScreen');
        developer.log('  - dateTime: "${_getPostDateTime(firstEvent)}"', name: 'SearchScreen');
        developer.log('  - additionalData: ${firstEvent.additionalData}', name: 'SearchScreen');
      }
      
      final filteredEvents = events.where((event) {
        final text = (event.text ?? '').toLowerCase();
        final interest = _getPostInterest(event).toLowerCase();
        final location = _getPostLocation(event).toLowerCase();
        final dateTime = _getPostDateTime(event).toLowerCase();
        
        // Check if any field contains the search query
        final textMatch = text.contains(query);
        final interestMatch = interest.isNotEmpty && interest.contains(query);
        final locationMatch = location.isNotEmpty && location.contains(query);
        final dateTimeMatch = dateTime.contains(query);
        
        final matches = textMatch || interestMatch || locationMatch || dateTimeMatch;
        
        // Only log events that have content or match
        if (matches || text.isNotEmpty) {
          developer.log('Event: "${text.length > 50 ? text.substring(0, 50) + '...' : text}"', name: 'SearchScreen');
          developer.log('Query="$query", matches: text=$textMatch, interest=$interestMatch, location=$locationMatch, dateTime=$dateTimeMatch', name: 'SearchScreen');
        }
        
        return matches;
      }).toList();
      
      developer.log('Filtered events count: ${filteredEvents.length}', name: 'SearchScreen');
      
      // Log some matching events
      if (filteredEvents.isNotEmpty) {
        developer.log('Sample matching events:', name: 'SearchScreen');
        for (int i = 0; i < math.min(3, filteredEvents.length); i++) {
          developer.log('  - "${filteredEvents[i].text}"', name: 'SearchScreen');
        }
      }
      
      return filteredEvents;
      
    } catch (e, stackTrace) {
      developer.log('Search events error: $e', name: 'SearchScreen', stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> _performSearch() async {
    // Prevent multiple simultaneous searches
    if (_isLoading) {
      developer.log('Search already in progress, skipping', name: 'SearchScreen');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated ||
          authProvider.token == null ||
          authProvider.userId == null) {
        authProvider.handleAuthError(
            context, AuthenticationException('Not authenticated'));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final token = authProvider.token!;
      final userId = authProvider.userId!;
      final query = _searchController.text.toLowerCase().trim();
      
      if (query.isEmpty) {
        setState(() {
          _goalResults = [];
          _eventResults = [];
          _challengeResults = [];
          _userResults = [];
          _isLoading = false;
        });
        return;
      }
      
      developer.log('Performing search with query: "$query" for tab: $_currentTabIndex', name: 'SearchScreen');

      // Search only for the current active tab
      switch (_currentTabIndex) {
        case 0: // Goals tab
          try {
            final goalResults = await _searchGoals(query, token, userId);
            if (mounted) {
              developer.log('Goals search completed: ${goalResults.length} results', name: 'SearchScreen');
              setState(() {
                _goalResults = goalResults;
                _isLoading = false;
              });
            }
          } catch (e) {
            developer.log('Goals search failed: $e', name: 'SearchScreen');
            if (mounted) {
              setState(() {
                _goalResults = [];
                _isLoading = false;
              });
            }
          }
          break;
          
        case 1: // Events tab
          try {
            final eventResults = await _searchEvents(query, token, userId);
            if (mounted) {
              developer.log('Events search completed: ${eventResults.length} results', name: 'SearchScreen');
              setState(() {
                _eventResults = eventResults;
                _isLoading = false;
              });
            }
          } catch (e) {
            developer.log('Events search failed: $e', name: 'SearchScreen');
            if (mounted) {
              setState(() {
                _eventResults = [];
                _isLoading = false;
              });
            }
          }
          break;
          
        case 2: // Challenges tab
          try {
            final challengeResults = await _searchChallenges(query);
            if (mounted) {
              developer.log('Challenges search completed: ${challengeResults.length} results', name: 'SearchScreen');
              setState(() {
                _challengeResults = challengeResults;
                _isLoading = false;
              });
            }
          } catch (e) {
            developer.log('Challenges search failed: $e', name: 'SearchScreen');
            if (mounted) {
              setState(() {
                _challengeResults = [];
                _isLoading = false;
              });
            }
          }
          break;
          
        case 3: // Users tab
          try {
            final userResults = await _searchUsers(query, token, userId);
            if (mounted) {
              developer.log('Users search completed: ${userResults.length} results', name: 'SearchScreen');
              setState(() {
                _userResults = userResults;
                _isLoading = false;
              });
            }
          } catch (e) {
            developer.log('Users search failed: $e', name: 'SearchScreen');
            if (mounted) {
              setState(() {
                _userResults = [];
                _isLoading = false;
              });
            }
          }
          break;
      }
    } catch (e, stackTrace) {
      developer.log('Search error: $e',
          name: 'SearchScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: ${e.toString().split(':').last.trim()}')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchChallenges(String query) async {
    return _allChallenges.where((challenge) {
      final title = challenge['title'].toString().toLowerCase();
      final description = challenge['description'].toString().toLowerCase();
      final keywords = challenge['keywords'] as List<String>;
      
      return title.contains(query) || 
             description.contains(query) ||
             keywords.any((keyword) => keyword.toLowerCase().contains(query));
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query, String token, String userId) async {
    try {
      return await _apiService.searchUsers(query, token: token, userId: userId);
    } catch (e) {
      developer.log('Search users error: $e', name: 'SearchScreen');
      return [];
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
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(color: Color(0xFF333333)),
                        filled: true,
                        fillColor: const Color(0xFFDDDDDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF333333)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF333333)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    // Clear only current tab results
                                    switch (_currentTabIndex) {
                                      case 0:
                                        _goalResults = [];
                                        break;
                                      case 1:
                                        _eventResults = [];
                                        break;
                                      case 2:
                                        _challengeResults = [];
                                        break;
                                      case 3:
                                        _userResults = [];
                                        break;
                                    }
                                  });
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Image.asset('assets/images/messages_icon.png', height: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFAFCBEA),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Goals'),
                Tab(text: 'Events'), 
                Tab(text: 'Challenge'),
                Tab(text: 'People'),
              ],
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGoalsTab(),
                        _buildEventsTab(),
                        _buildChallengesTab(),
                        _buildPeopleTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 1,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildGoalsTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to find goals',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16),
        ),
      );
    }
    
    if (_goalResults.isEmpty) {
      return const Center(
        child: Text(
          'No goals found',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goalResults.length,
      itemBuilder: (context, index) {
        final goal = _goalResults[index];
        return _buildPostCard(goal, 'goal');
      },
    );
  }

  Widget _buildEventsTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to find events',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16),
        ),
      );
    }
    
    if (_eventResults.isEmpty) {
      return const Center(
        child: Text(
          'No events found',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventResults.length,
      itemBuilder: (context, index) {
        final event = _eventResults[index];
        return _buildPostCard(event, 'event');
      },
    );
  }

  Widget _buildChallengesTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to find challenges',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16),
        ),
      );
    }
    
    if (_challengeResults.isEmpty) {
      return const Center(
        child: Text(
          'No challenges found',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challengeResults.length,
      itemBuilder: (context, index) {
        final challenge = _challengeResults[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildPeopleTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to find people',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16),
        ),
      );
    }
    
    if (_userResults.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(
          profileImage: user['profileImage'] ?? '',
          username: user['username'] ?? 'Unknown',
          biography: user['biography'] ?? 'No biography',
          numOfFollowers: user['numOfFollowers'] ?? 0,
        );
      },
    );
  }

  Widget _buildPostCard(Post post, String type) {
    return Card(
      color: const Color(0xFFDDDDDD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: post.id,
                postType: type,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
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
                        if (_getPostInterest(post).isNotEmpty)
                          Text(
                            _getPostInterest(post),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: type == 'goal' ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: type == 'goal' ? Colors.blue[800] : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Media
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                _buildMediaWidget(post),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                post.text ?? 'No description',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (_getPostLocation(post).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Text(
                      _getPostLocation(post),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  Text(
                    '${post.numOfLikes} likes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${post.numComments} comments',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      return Container(
        height: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 150,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    return Card(
      color: const Color(0xFFDDDDDD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${challenge['title']}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
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
                    image: AssetImage(challenge['imageAsset']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String profileImage,
    required String username,
    required String biography,
    required int numOfFollowers,
  }) {
    return Card(
      color: const Color(0xFFDDDDDD),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              backgroundColor: const Color(0xFF333333),
              radius: 30,
              child: profileImage.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    biography,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$numOfFollowers followers',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: Color(0xFFAFCBEA)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Following $username')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}