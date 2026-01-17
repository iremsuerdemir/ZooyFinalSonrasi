import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zoozy/models/pet_walk_model.dart';
import 'package:zoozy/services/pet_walk_service.dart';

class SavedPetWalksPage extends StatefulWidget {
  const SavedPetWalksPage({super.key});

  @override
  State<SavedPetWalksPage> createState() => _SavedPetWalksPageState();
}

class _SavedPetWalksPageState extends State<SavedPetWalksPage> {
  List<PetWalk> walks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedWalks();
  }

  Future<void> _loadSavedWalks() async {
    final list = await PetWalkService().getWalks();

    debugPrint('📦 Saved walks count: ${list.length}');

    if (mounted) {
      setState(() {
        walks = list; // API already returns ordered by date desc
        loading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _petNames(List<PetWalkItem> pets) {
    final names = pets
        .map((p) => p.type)
        .where((e) => e.isNotEmpty)
        .toList();

    if (names.isEmpty) return 'Evcil Hayvanlar';
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient arka plan
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB39DDB),
                  Color(0xFFF48FB1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar benzeri üst bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kayıtlı Yürüyüşler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // İçerik
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : walks.isEmpty
                          ? const Center(
                              child: Text(
                                'Henüz kayıtlı yürüyüş yok',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = math.min(
                                    constraints.maxWidth * 0.95, 900).toDouble();

                                return Center(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    itemCount: walks.length,
                                    itemBuilder: (context, index) {
                                      final walk = walks[index];
                                      final date = DateTime.parse(walk.date);
                                      final pets = walk.pets;
                                      final duration =
                                          Duration(seconds: walk.durationSeconds);
                                      final distance = walk.distanceKm;

                                      return Container(
                                        width: maxWidth,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepPurple,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.pets,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _formatDate(date),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      _petNames(pets),
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                _infoItem(
                                                    Icons.timer,
                                                    _formatDuration(
                                                        duration)),
                                                Container(
                                                  width: 1,
                                                  height: 40,
                                                  color: Colors.grey.shade300,
                                                ),
                                                _infoItem(
                                                    Icons.route,
                                                    '${distance.toStringAsFixed(2)} km'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

const List<String> _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];
