import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zoozy/models/pet_walk_model.dart';
import 'package:zoozy/screens/saved_pet_walks_page.dart';
import 'package:zoozy/services/pet_walk_service.dart';

class CompletedPetWalkPage extends StatefulWidget {
  const CompletedPetWalkPage({
    super.key,
    required this.duration,
    required this.distanceInKm,
    required this.selectedPets,
    required this.path,
  });

  final Duration duration;
  final double distanceInKm;
  final List<Map<String, dynamic>> selectedPets;
  final List<LatLng> path;

  @override
  State<CompletedPetWalkPage> createState() => _CompletedPetWalkPageState();
}

class _CompletedPetWalkPageState extends State<CompletedPetWalkPage> {
  bool _saved = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Future<void> _saveWalkOnce() async {
    if (_saved) return;
    _saved = true;

    final walk = PetWalk(
      userId: 0, // Service will set correct id
      durationSeconds: widget.duration.inSeconds,
      distanceKm: widget.distanceInKm,
      pets: widget.selectedPets.map((pet) => PetWalkItem(type: pet["type"])).toList(),
      path: widget.path.map((e) => PathPoint(lat: e.latitude, lng: e.longitude)).toList(),
      date: DateTime.now().toIso8601String(),
    );

    final success = await PetWalkService().saveWalk(walk);
    if (success) {
      debugPrint("✅ Walk saved to backend.");
    } else {
      debugPrint("❌ Failed to save walk to backend.");
      // _saved = false; // belki retry imkanı sunulabilir
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yürüyüş kaydedilemedi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finishDate = DateTime.now();
    final formattedDate =
        '${finishDate.day} ${_months[finishDate.month - 1]} ${finishDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvan Yürüyüşleri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            color: Colors.green.shade600,
            child: const Text(
              'Yürüyüş Bilgileri Başarıyla Kaydedildi.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tamamlanan Yürüyüş',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(formattedDate),
                      ],
                    ),
                  ),
                ),
                // 🗺️ HARİTA
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GoogleMap(
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                      initialCameraPosition: CameraPosition(
                        target: widget.path.isNotEmpty
                            ? widget.path.last
                            : const LatLng(41.0082, 28.9784),
                        zoom: 15,
                      ),
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('completed_path'),
                          points: widget.path,
                          width: 6,
                          color: Colors.deepPurple,
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.orange.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _petNames(),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              // ✅ Sağdaki history ikonu
              IconButton(
                icon: const Icon(Icons.history, color: Colors.deepPurple),
                tooltip: 'Kayıtlı Yürüyüşler',
                onPressed: () async {
                  await _saveWalkOnce(); // yürüyüşü kaydet
                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedPetWalksPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoColumn(Icons.timer, _formatDuration(widget.duration)),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _infoColumn(
                Icons.route,
                '${widget.distanceInKm.toStringAsFixed(2)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _petNames() {
    final names = widget.selectedPets
        .map((pet) => pet['type'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    return names.isEmpty ? 'Evcil Hayvanlar' : names.join(', ');
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
