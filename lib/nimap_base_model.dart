class NimapBaseModel {
  final int status;
  final String message;
  final dynamic data;
  NimapBaseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory NimapBaseModel.fromJson(Map<String, dynamic> json) {
    return NimapBaseModel(
      status: json['status'] ?? 0,
      message: json['error'] ?? '',
      data: json['data'],
    );
  }

  bool isEmpty() {
    return status == 0 && message.isEmpty && data == null;
  }
}
