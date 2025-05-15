// models/strava_activity.dart

class StravaActivity {
  final int? id;
  final String stravaId;
  final String name;
  final double distance; // en mètres
  final int duration; // en secondes
  final double elevation; // en mètres
  final String type; // ex: Run, Ride, etc.
  final DateTime date;

  StravaActivity({
    this.id,
    required this.stravaId,
    required this.name,
    required this.distance,
    required this.duration,
    required this.elevation,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strava_id': stravaId,
      'name': name,
      'distance': distance,
      'duration': duration,
      'elevation': elevation,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory StravaActivity.fromMap(Map<String, dynamic> map) {
    return StravaActivity(
      id: map['id'],
      stravaId: map['strava_id'],
      name: map['name'],
      distance: map['distance'],
      duration: map['duration'],
      elevation: map['elevation'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}
