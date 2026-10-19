import 'package:flutter/material.dart';
import '../widgets/reusable_row.dart';

/// Screen displaying detailed COVID-19 statistics for a specific country.
class DetailScreen extends StatelessWidget {
  final String image;
  final String name;
  final int totalCases;
  final int totalDeaths;
  final int totalRecovered;
  final int active;
  final int critical;
  final int todayRecovered;
  final int test;

  const DetailScreen({
    super.key,
    required this.image,
    required this.name,
    required this.totalCases,
    required this.totalDeaths,
    required this.totalRecovered,
    required this.active,
    required this.critical,
    required this.todayRecovered,
    required this.test,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.067),
                  child: Card(
                    child: Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.06),
                        ReusableRow(
                            title: 'Total Cases',
                            value: totalCases.toString()),
                        ReusableRow(
                            title: 'Recovered',
                            value: totalRecovered.toString()),
                        ReusableRow(
                            title: 'Deaths',
                            value: totalDeaths.toString()),
                        ReusableRow(
                            title: 'Critical', value: critical.toString()),
                        ReusableRow(
                            title: 'Today Recovered',
                            value: todayRecovered.toString()),
                        ReusableRow(title: 'Tests', value: test.toString()),
                      ],
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(image),
                  onBackgroundImageError: (exception, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}