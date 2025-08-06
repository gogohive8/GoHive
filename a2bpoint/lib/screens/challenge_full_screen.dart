import 'package:flutter/material.dart';
import '../screens/task_detail_screen.dart';
import 'dart:developer' as developer;
import '../screens/home_screen.dart';
import '../screens/post_detail_screen.dart';


class ChallengeFullScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<List<TaskItem>> tasks;
  final String headerImageAsset;

  const ChallengeFullScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.headerImageAsset,
  }) : super(key: key);

  @override
  State<ChallengeFullScreen> createState() => _ChallengeFullScreenState();
}

class _ChallengeFullScreenState extends State<ChallengeFullScreen> {
  late List<List<TaskItem>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks
        .map((day) =>
        day
            .map((task) =>
            TaskItem(
              id: task.id,
              title: task.title,
              description: task.description,
              isCompleted: task.isCompleted,
            ))
            .toList())
        .toList();
  }

  void _toggleTask(int dayIndex, int taskIndex) {
    setState(() {
      _tasks[dayIndex][taskIndex].isCompleted =
      !_tasks[dayIndex][taskIndex].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    final horizontalMargin = size.width * 0.04;
    final verticalMargin = size.height * 0.015;

    return DefaultTabController(
      length: _tasks.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F1EC),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: size.height * 0.015,
                  left: size.width * 0.04,
                  right: size.width * 0.04,
                  bottom: size.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 160,
                        height: size.height * 0.18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: AssetImage(widget.headerImageAsset),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BackButton(color: Color(0xFF222220)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 100.0),
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: const Color(0xFF222220),
                                fontSize: size.width * 0.075,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                              vertical: verticalMargin,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EFEA),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.0001,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                isScrollable: true,
                                indicator: BoxDecoration(
                                  color: const Color(0xFFFDFDFD),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                indicatorColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                physics: const ClampingScrollPhysics(),
                                labelPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                labelColor: const Color(0xFF222220),
                                unselectedLabelColor: const Color(0xFF676767),
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                tabs: List.generate(
                                  _tasks.length,
                                      (index) => Tab(text: 'Day ${index + 1}'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: List.generate(
                    _tasks.length,
                        (dayIndex) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            if (dayIndex == 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, bottom: 16.0, right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'The challenge begins',
                                      style: TextStyle(
                                        fontFamily: 'TT Norms Pro Trial',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF222220),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Start completing tasks and checking them off. You\'ll do great!',
                                      style: TextStyle(
                                        fontFamily: 'TT Norms Pro Trial',
                                        fontSize: 19,
                                        color: Color(0xFF222220),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ...List.generate(
                              _tasks[dayIndex].length,
                                  (taskIndex) =>
                                  _buildTaskCard(
                                      _tasks[dayIndex][taskIndex],
                                      size,
                                          () =>
                                          _toggleTask(dayIndex, taskIndex)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task, Size size, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6),
      child: Stack(
         children: [
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                color: const Color(0xFF222220),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Кнопка комментариев
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskDetailScreen(
                                      postId: task.id, postType: 'Challenge'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            bottom: 5,
            child: Column(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFBDBBB9), width: 6),
                      color: task.isCompleted ? Colors.blue : Colors.white,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check,
                        color: Colors.black, size: 16)
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFBDBBB9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}