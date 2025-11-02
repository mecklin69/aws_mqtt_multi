// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../constants/app_colors.dart' as app_colors;
// import '../../responsive/responsive_layout.dart';
//
// class LocationLineChart extends StatelessWidget {
//   const LocationLineChart({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Determine the aspect ratio based on screen size for better responsiveness
//     double aspectRatio = Responsive.isMobile(context) ? 1.2 : 2.5;
//
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             spreadRadius: 1,
//             blurRadius: 10,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Sensor Data Over Time',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 24),
//           AspectRatio(
//             aspectRatio: aspectRatio,
//             child: LineChart(
//               LineChartData(
//                 // FIX: Removed 'const' and explicitly referenced the static method
//                 // using the class name for clear and correct compilation.
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: true,
//                   horizontalInterval: 1,
//                   verticalInterval: 1,
//                   getDrawingHorizontalLine: LocationLineChart.defaultGet,
//                   getDrawingVerticalLine: LocationLineChart.defaultGet,
//                 ),
//                 titlesData: FlTitlesData(
//                   show: true,
//                   rightTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   topTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 30,
//                       interval: 1,
//                       // FIX: Referenced static method via class name
//                       getTitlesWidget: LocationLineChart.bottomTitleWidgets,
//                     ),
//                   ),
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       interval: 5,
//                       // FIX: Referenced static method via class name
//                       getTitlesWidget: LocationLineChart.leftTitleWidgets,
//                       reservedSize: 40,
//                     ),
//                   ),
//                 ),
//                 borderData: FlBorderData(
//                   show: true,
//                   border: Border.all(color: app_colors.slateGrey.withOpacity(0.3), width: 1),
//                 ),
//                 minX: 0,
//                 maxX: 11,
//                 minY: 0,
//                 maxY: 30,
//                 lineBarsData: showingLineBarsData(),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Legend
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24.0),
//             child: Wrap(
//               spacing: 20.0,
//               runSpacing: 10.0,
//               children: [
//                 ChartLegend(color: app_colors.activeBlue, text: 'Temperature (°C)'),
//                 ChartLegend(color: app_colors.indicatorOrange, text: 'Humidity (%)'),
//                 ChartLegend(color: app_colors.statusGreen, text: 'Pressure (kPa)'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- Chart Helper Functions (Now STATIC) ---
//
//   // Made static to ensure correct binding in LineChartData
//   static Widget bottomTitleWidgets(double value, TitleMeta meta) {
//     const style = TextStyle(
//       fontWeight: FontWeight.bold,
//       fontSize: 12,
//       color: app_colors.slateGrey,
//     );
//     Widget text;
//     switch (value.toInt()) {
//       case 2:
//         text = const Text('MAR', style: style);
//         break;
//       case 5:
//         text = const Text('JUN', style: style);
//         break;
//       case 8:
//         text = const Text('SEP', style: style);
//         break;
//       case 11:
//         text = const Text('DEC', style: style);
//         break;
//       default:
//         text = const Text('', style: style);
//         break;
//     }
//     return SideTitleWidget(child: text, meta: meta);
//
//   }
//
//   // Made static to ensure correct binding in LineChartData
//   static Widget leftTitleWidgets(double value, TitleMeta meta) {
//     const style = TextStyle(
//       fontWeight: FontWeight.bold,
//       fontSize: 12,
//       color: app_colors.slateGrey,
//     );
//     String text;
//     if (value.toInt() % 5 == 0) {
//       text = value.toInt().toString();
//     } else {
//       return Container();
//     }
//     return Text(text, style: style, textAlign: TextAlign.left);
//   }
//
//   List<LineChartBarData> showingLineBarsData() {
//     return [
//       // Line 1: Temperature (Blue)
//       LineChartBarData(
//         spots: const [
//           FlSpot(0, 15),
//           FlSpot(2.6, 18),
//           FlSpot(4.9, 25),
//           FlSpot(6.8, 23),
//           FlSpot(8, 20),
//           FlSpot(9.5, 24),
//           FlSpot(11, 28),
//         ],
//         isCurved: true,
//         gradient: const LinearGradient(
//           colors: [app_colors.activeBlue, app_colors.darkBlue],
//         ),
//         barWidth: 4,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData: BarAreaData(
//           show: true,
//           gradient: LinearGradient(
//             colors: [
//               app_colors.activeBlue.withOpacity(0.3),
//               app_colors.activeBlue.withOpacity(0),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//       ),
//       // Line 2: Humidity (Orange)
//       LineChartBarData(
//         spots: const [
//           FlSpot(0, 20),
//           FlSpot(2, 22),
//           FlSpot(3.5, 17),
//           FlSpot(6, 19),
//           FlSpot(7.5, 15),
//           FlSpot(10, 18),
//           FlSpot(11, 14),
//         ],
//         isCurved: true,
//         color: app_colors.indicatorOrange,
//         barWidth: 4,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData:  BarAreaData(show: false),
//       ),
//       // Line 3: Pressure (Green)
//       LineChartBarData(
//         spots: const [
//           FlSpot(0, 8),
//           FlSpot(1.5, 12),
//           FlSpot(4, 10),
//           FlSpot(5.5, 16),
//           FlSpot(8.5, 14),
//           FlSpot(10, 19),
//           FlSpot(11, 15),
//         ],
//         isCurved: true,
//         color: app_colors.statusGreen,
//         barWidth: 4,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData:  BarAreaData(show: false),
//       ),
//     ];
//   }
//
//   // Define a simple default line drawing function for grid
//   static FlLine defaultGet(double value) {
//     return FlLine(
//       color: app_colors.slateGrey.withOpacity(0.15),
//       strokeWidth: 1,
//     );
//   }
// }
//
// // Helper widget for chart legend/indicators
// class ChartLegend extends StatelessWidget {
//   final Color color;
//   final String text;
//
//   const ChartLegend({
//     super.key,
//     required this.color,
//     required this.text,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color,
//           ),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: app_colors.slateGrey.withOpacity(0.9),
//           ),
//         )
//       ],
//     );
//   }
// }
