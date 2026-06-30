class JobModel {
  final String id;
  final String clientId;
  final String imageUrl;
  final String description;
  final double cost;
  final String status; // 'received', 'in_progress', 'completed', 'delivered'
  final String recordedByUid;
  final String recordedByName;
  final DateTime date;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.clientId,
    required this.imageUrl,
    required this.description,
    required this.cost,
    required this.status,
    required this.recordedByUid,
    required this.recordedByName,
    required this.date,
    required this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      clientId: map['clientId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'received',
      recordedByUid: map['recordedByUid'] ?? '',
      recordedByName: map['recordedByName'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'imageUrl': imageUrl,
      'description': description,
      'cost': cost,
      'status': status,
      'recordedByUid': recordedByUid,
      'recordedByName': recordedByName,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
