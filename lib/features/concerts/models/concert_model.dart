class Concert {
  final String id;
  final String imageUrl;
  final String artistName;
  final String concertName;
  final List<String> description;
  final List<String> dates;
  final String location;
  final String artistDetails;
  final List<String> concertMusic;

  Concert({
    required this.id,
    required this.imageUrl,
    required this.artistName,
    required this.concertName,
    required this.description,
    required this.dates,
    required this.location,
    required this.artistDetails,
    required this.concertMusic,
  });

  factory Concert.fromMap(Map<String, dynamic> map, String id) {
    // Helper functions for parsing arrays
    List<String> parseDates(dynamic datesData) {
      if (datesData is List) {
        return datesData.map((date) => date.toString()).toList();
      } else if (datesData is String) {
        return [datesData];
      }
      return [];
    }

    List<String> parseDescription(dynamic descriptionData) {
      if (descriptionData is List) {
        return descriptionData.map((para) => para.toString()).toList();
      } else if (descriptionData is String) {
        return [descriptionData];
      }
      return [];
    }

    List<String> parseMusic(dynamic musicData) {
      if (musicData is List) {
        return musicData.map((song) => song.toString()).toList();
      } else if (musicData is String) {
        return [musicData];
      }
      return [];
    }

    return Concert(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      artistName: map['artistName'] ?? '',
      concertName: map['concertName'] ?? '',
      description: parseDescription(map['description']),
      dates: parseDates(map['dates']),
      location: map['location'] ?? '',
      artistDetails: map['artistDetails'] ?? '',
      concertMusic: parseMusic(map['concertMusic']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'artistName': artistName,
      'concertName': concertName,
      'description': description,
      'dates': dates,
      'location': location,
      'artistDetails': artistDetails,
      'concertMusic': concertMusic,
    };
  }
}