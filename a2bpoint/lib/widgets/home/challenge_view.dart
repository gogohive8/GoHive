// widgets/home/challenge_view.dart
import 'package:GoHive/models/task_item.dart';
import 'package:flutter/material.dart';
import '../../screens/challenge_full_screen.dart';
import '../../data/challenge_data.dart';
import 'challenge_card.dart';
import 'missions_background_painter.dart';

class ChallengeView extends StatelessWidget {
  const ChallengeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      ChallengeCard(
                        title: 'The "Tidy Up" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/tidy_challenge.png',
                        onTap: () => _navigateToChallenge(
                          context,
                          'The "Tidy Up" Challenge',
                          'Start cleaning up and stay organized!',
                          'assets/images/tidy_challenge.png',
                          ChallengeData.tidyChallengeTasks,
                        ),
                      ),
                      ChallengeCard(
                        title: 'The "Moon" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/moon_challenge.png',
                        onTap: () => _navigateToChallenge(
                          context,
                          'The "Moon" Challenge',
                          'Find inner peace and mindfulness!',
                          'assets/images/moon_challenge.png',
                          ChallengeData.moonChallengeTasks,
                        ),
                      ),
                      ChallengeCard(
                        title: 'The "Animal" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/animal_challenge.png',
                        onTap: () => _navigateToChallenge(
                          context,
                          'The "Animal" Challenge',
                          'Connect with your wild side!',
                          'assets/images/animal_challenge.png',
                          ChallengeData.animalChallengeTasks,
                        ),
                      ),
                      ChallengeCard(
                        title: 'The "Dance" Challenge',
                        description: '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/dance_challenge.png',
                        onTap: () => _navigateToChallenge(
                          context,
                          'The "Dance" Challenge',
                          'Move your body and feel the rhythm!',
                          'assets/images/dance_challenge.png',
                          ChallengeData.danceChallengeTasks,
                        ),
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

  void _navigateToChallenge(
    BuildContext context,
    String title,
    String subtitle,
    String imageAsset,
    List<List<TaskItem>> tasks,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeFullScreen(
          title: title,
          subtitle: subtitle,
          headerImageAsset: imageAsset,
          tasks: tasks,
        ),
      ),
    );
  }
}