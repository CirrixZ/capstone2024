import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool isEditable;
  final Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24,
    this.isEditable = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double value = index + 1;
        IconData icon;
        Color color;

        if (rating >= value) {
          icon = Icons.star;
          color = Colors.amber;
        } else if (rating > index) {
          icon = Icons.star_half;
          color = Colors.amber;
        } else {
          icon = Icons.star_border;
          color = Colors.grey;
        }

        return GestureDetector(
          onTapDown: isEditable
              ? (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  final double percent = localPosition.dx / (size * 5);
                  double rating = (percent * 10).round() / 2;
                  rating = rating.clamp(0.0, 5.0);
                  onRatingChanged?.call(rating);
                }
              : null,
          child: Icon(icon, size: size, color: color),
        );
      }),
    );
  }
}