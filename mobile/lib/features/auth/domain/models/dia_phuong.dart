/// Model representing an administrative locality (province / city).
class DiaPhuong {
  final int id;
  final String ten;
  final String? loai;

  const DiaPhuong({
    required this.id,
    required this.ten,
    this.loai,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaPhuong &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ten == other.ten &&
          loai == other.loai;

  @override
  int get hashCode => id.hashCode ^ ten.hashCode ^ loai.hashCode;
}
