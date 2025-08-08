// widgets/home/challenge_card.dart
import 'package:flutter/material.dart';

class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;
  final VoidCallback onTap;

  const ChallengeCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Color(0xFF666666)
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
                  image: AssetImage(imageAsset), 
                  fit: BoxFit.cover
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}