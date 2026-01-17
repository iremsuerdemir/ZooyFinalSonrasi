
class PetWalk {
  final int? id;
  final int userId;
  final int durationSeconds;
  final double distanceKm;
  final List<PathPoint> path;
  final List<PetWalkItem> pets;
  final String date;

  PetWalk({
    this.id,
    required this.userId,
    required this.durationSeconds,
    required this.distanceKm,
    required this.path,
    required this.pets,
    required this.date,
  });

  factory PetWalk.fromJson(Map<String, dynamic> json) {
    return PetWalk(
      id: json['id'],
      userId: json['userId'],
      durationSeconds: json['durationSeconds'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      date: json['date'],
      path: (json['path'] as List?)
          ?.map((e) => PathPoint.fromJson(e))
          .toList() ?? [],
      pets: (json['pets'] as List?)
          ?.map((e) => PetWalkItem.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'date': date,
      'path': path.map((e) => e.toJson()).toList(),
      'pets': pets.map((e) => e.toJson()).toList(),
    };
  }
}

class PathPoint {
  final double lat;
  final double lng;

  PathPoint({required this.lat, required this.lng});

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    return PathPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class PetWalkItem {
  final String type;

  PetWalkItem({required this.type});

  factory PetWalkItem.fromJson(Map<String, dynamic> json) {
    return PetWalkItem(
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'type': type};
}
