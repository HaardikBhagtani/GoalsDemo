import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key});

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  @override
  void initState() {
    // seedFirestore();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: FutureBuilder(
        future: _fetchGoalData(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Extract data from the snapshot
            var goalData = <String, dynamic>{};
            if (snapshot.data!.docs.isNotEmpty) {
              goalData = snapshot.data!.docs[0].data();
            } else {
              return const SizedBox.shrink();
            }

            return _buildGoalDetailUI(goalData);
          }
        },
      ),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchGoalData() async {
    return await FirebaseFirestore.instance.collection('goals').limit(1).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchContributionsData() async {
    return await FirebaseFirestore.instance.collection('contributions').get();
  }

  Widget _buildGoalDetailUI(Map<String, dynamic> goalData) {
    return FutureBuilder(
      future: _fetchContributionsData(),
      builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }

          int savings = 0;
          for (var contribution in snapshot.data!.docs) {
            savings += int.parse(contribution.data()["amount"].toString());
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(goalData["name"],
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
              SfRadialGauge(
                enableLoadingAnimation: true,
                axes: [
                  RadialAxis(
                    showTicks: false,
                    showLabels: false,
                    ranges: <GaugeRange>[
                      GaugeRange(startValue: 0, endValue: (goalData['totalAmountSaved'] / goalData['targetAmount']) * 100, color: Colors.white),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.home_filled,
                              color: Colors.white,
                              size: 120,
                            ),
                            Text(
                              '₹ ${goalData['totalAmountSaved']}',
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'You Saved',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.6,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Goals',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(
                            'by ${DateFormat('MMM yyyy').format(DateTime.now().add(Duration(days: ((goalData['targetAmount'] - goalData['totalAmountSaved']) ~/ (savings ~/ snapshot.data!.docs.length)) * 30)))}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            )),
                      ],
                    ),
                    Text('₹ ${goalData['targetAmount']}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Need more savings',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )),
                          Text('₹ ${goalData['targetAmount'] - goalData['totalAmountSaved']}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monthly Saving Projection',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )),
                          Text('₹ ${savings ~/ snapshot.data!.docs.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  seedFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final goalsCollection = firestore.collection('goals');
    final contributionsCollection = firestore.collection('contributions');

    final goalDoc = await goalsCollection.add({
      "name": 'Buy a Dream House',
      "targetAmount": 50000,
      "totalAmountSaved": 25000,
      "expectedCompletionDate": Timestamp.fromDate(DateTime(2030)),
    });

    await contributionsCollection.add({
      "goalId": goalDoc.id,
      "amount": 250,
      "date": Timestamp.fromDate(DateTime(2024)),
    });
  }
}
