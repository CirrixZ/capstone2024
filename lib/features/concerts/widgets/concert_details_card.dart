import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/features/analytics/screens/analytics.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/concerts/widgets/music_dialog.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/concerts/widgets/artist_dialog.dart';
import 'package:intl/intl.dart';

class ConcertDetailsCard extends StatelessWidget {
  final Concert concert;
  final bool isAdmin;
  final String concertId;

  const ConcertDetailsCard({
    super.key,
    required this.concert,
    required this.isAdmin,
    required this.concertId,
  });

  String _formatDate(String date) {
    try {
      // Assuming the input date is in yyyy-mm-dd format
      final DateTime parsedDate = DateTime.parse(date);
      final DateFormat formatter = DateFormat('MMMM d, yyyy');
      return formatter.format(parsedDate);
    } catch (e) {
      // Return original string if parsing fails
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainCard(context),
        SizedBox(height: 10),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2F1552),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConcertImage(),
          SizedBox(height: 16),
          _buildConcertInfo(),
          SizedBox(height: 16),
          _buildDateAndLocation(),
        ],
      ),
    );
  }

  Widget _buildConcertImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        concert.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildConcertInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          concert.concertName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...concert.description.map((paragraph) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                paragraph,
                style: TextStyle(color: Colors.white70),
              ),
            )),
      ],
    );
  }

  Widget _buildDateAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First date with formatting
        Row(
          children: [
            Icon(
              Icons.calendar_today, // The date icon
              color: AppColors.iconColor, // Adjust the color if needed
              size: 16, // Adjust the size if needed
            ),
            SizedBox(width: 8), // Space between icon and text
            Text(
              concert.dates.isNotEmpty
                  ? _formatDate(concert.dates.first)
                  : 'No date available',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        // Additional dates with formatting
        if (concert.dates.length > 1)
          ...concert.dates.skip(1).map((date) => Padding(
                padding: const EdgeInsets.only(
                    left:
                        24.0), // padding to align next dates to the first date
                child: Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.white70),
                ),
              )),
        SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.location_on,
          text: concert.location,
        ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.iconColor),
        SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildArtistButton(context),
              SizedBox(width: 16),
              _buildMusicButton(context),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AnalyticsPage(concertId: concertId)),
                  ),
                  child: const Text(
                    'Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => ArtistDialog.showArtistDialog(
        context,
        artistName: concert.artistName,
        artistDetails: concert.artistDetails,
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFF592D6D), width: 3.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Artist',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildMusicButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => MusicDialog.showMusicDialog(
        context,
        concertName: concert.concertName,
        concertMusic: concert.concertMusic,
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFF592D6D), width: 3.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Setlist',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
