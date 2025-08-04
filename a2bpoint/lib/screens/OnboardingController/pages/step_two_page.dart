import 'package:flutter/material.dart';
import '../onboarding_controller.dart';

class StepTwoPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final bool isLoading;

  const StepTwoPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.isLoading,
  });

  @override
  State<StepTwoPage> createState() => _StepTwoPageState();
}

class _StepTwoPageState extends State<StepTwoPage> {
  final List<List<String>> _interestGroups = [
    ['Money', 'Relationships', 'Purpose'],
    ['Health', 'Mental health', 'Society'],
    ['Others']
  ];

  Set<String> _selectedInterests = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set<String>.from(widget.data.interests);
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    widget.data.interests = _selectedInterests.toList();
  }

  void _continue() {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onNext();
  }

  double _getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double _getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = _getResponsiveWidth(context);
    final screenHeight = _getResponsiveHeight(context);
    final padding = screenWidth * 0.08;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3EE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            
            // Title
            Text(
              'Please indicate your interests',
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.04),

            // Interest Groups
            Expanded(
              child: ListView.separated(
                itemCount: _interestGroups.length,
                separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.03),
                itemBuilder: (context, groupIndex) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group name',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildInterestRow(_interestGroups[groupIndex], screenWidth),
                    ],
                  );
                },
              ),
            ),
            
            SizedBox(height: screenHeight * 0.02),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056F7),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestRow(List<String> interests, double screenWidth) {
    return Wrap(
      spacing: screenWidth * 0.03,
      runSpacing: screenWidth * 0.025,
      children: interests.map((interest) => _buildInterestChip(interest, screenWidth)).toList(),
    );
  }

  Widget _buildInterestChip(String interest, double screenWidth) {
    final isSelected = _selectedInterests.contains(interest);
    
    return GestureDetector(
      onTap: () => _toggleInterest(interest),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0056F7) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF0056F7) : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0056F7).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          interest,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: screenWidth * 0.04,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}