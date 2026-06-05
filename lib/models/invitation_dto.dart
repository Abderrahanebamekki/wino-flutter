class InvitationDto {
  final int id;
  final String status;
  final String childFullName;
  final String parentFullName;

  InvitationDto({
    required this.id,
    required this.status,
    required this.childFullName,
    required this.parentFullName,
  });
}
