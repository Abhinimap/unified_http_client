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
      status: json['status'],
      message: json['error'],
      data: json['data'],
    );
  }
}
