// lib/features/ticket_market/models/ticket_model.dart

class Ticket {
  final String id;
  final String ticketName;
  final String url;

  Ticket({
    required this.id,
    required this.ticketName,
    required this.url,
  });

  factory Ticket.fromMap(Map<String, dynamic> map, String id) {
    return Ticket(
      id: id,
      ticketName: map['ticketName'] ?? '',
      url: map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketName': ticketName,
      'url': url,
    };
  }
}