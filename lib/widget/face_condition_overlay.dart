import 'package:flutter/material.dart';

class FaceConditionOverlay extends StatelessWidget {
  final Map<String, String> condition;
  final bool showDebugInfo;

  const FaceConditionOverlay({
    super.key,
    required this.condition,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color lightingColor;
    switch (condition['lighting']) {
      case 'Too Dark':
        lightingColor = Colors.blue;
        break;
      case 'Too Bright':
        lightingColor = Colors.orange;
        break;
      default:
        lightingColor = Colors.green;
    }

    Color expressionColor;
    switch (condition['expression']) {
      case 'Happy':
        expressionColor = Colors.green;
        break;
      case 'Sad':
        expressionColor = Colors.blue;
        break;
      case 'Tired':
        expressionColor = Colors.purple;
        break;
      case 'Stressed':
        expressionColor = Colors.red;
        break;
      default:
        expressionColor = Colors.grey;
    }

    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: expressionColor, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  _getExpressionIcon(condition['expression'] ?? 'Neutral'),
                  color: expressionColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Expression: ${condition['expression']}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lightingColor, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  _getLightingIcon(condition['lighting'] ?? 'Normal'),
                  color: lightingColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Lighting: ${condition['lighting']}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          if (showDebugInfo) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Debug Info: Active',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getExpressionIcon(String expression) {
    switch (expression) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Sad':
        return Icons.sentiment_very_dissatisfied;
      case 'Tired':
        return Icons.bedtime;
      case 'Stressed':
        return Icons.psychology;
      default:
        return Icons.sentiment_neutral;
    }
  }

  IconData _getLightingIcon(String lighting) {
    switch (lighting) {
      case 'Too Dark':
        return Icons.brightness_low;
      case 'Too Bright':
        return Icons.brightness_high;
      default:
        return Icons.brightness_medium;
    }
  }
}