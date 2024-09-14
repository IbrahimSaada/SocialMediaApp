class PresignedUrl {
  final String url;
  final String bucket;
  final String objectKey;

  PresignedUrl(this.url, this.bucket, this.objectKey);

  factory PresignedUrl.fromJson(Map<String, dynamic> json) {
    return PresignedUrl(
        json['presignedUrl'], json['bucket'], json['objectKey']);
  }
}
