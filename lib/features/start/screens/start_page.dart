import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/features/auth/screens/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'dart:ui';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // Background Image with Blur
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      "assets/images/spage.png"), // Path to your background image
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5), // Blur effect
                child: Container(
                  color: Colors.black
                      .withOpacity(0), // Transparent container for layout
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Use relative positioning based on screen height
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.05,
                    top: screenHeight * 0.2,
                  ),
                  child: Stack(
                    children: [
                      // Inner shadow effect with dynamic font size
                      GradientText(
                        'Unlock\nThe\nRhythm\nOf\nLive Music',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenHeight * 0.053, // Adjust font size
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 3,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        gradientDirection: GradientDirection.ttb,
                        gradientType: GradientType.linear,
                        colors: const [
                          Color(0xFF9C27B0), // Rich purple
                          Color(0xFF7B1FA2), // Deep purple
                          Color(0xFFAB47BC), // Light purple
                          Color(0xFFAB47BC), // Dark purple
                        ],
                        stops: const [
                          0.1,
                          0.4,
                          0.6,
                          0.9
                        ], // Control color distribution
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.3), // Dynamic spacing
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: screenWidth * 0.5, // Button width as 40% of screen width
                    height: screenHeight * 0.06, // Button height as 7% of screen height
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.authButtonColor),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthPage()),
                            ModalRoute.withName("/Home"));
                      },
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenHeight * 0.025, // Dynamic font size
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05), // Dynamic bottom spacing
              ],
            ),
          ],
        ),
      ),
    );
  }
}
