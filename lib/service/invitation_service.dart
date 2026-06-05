import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/invitation_dto.dart';
import 'auth_token_service.dart';
import 'api_service.dart';

class InvitationService {
  static Future<void> inviteGuarantor({
    required String phoneNumber,
    required int childId,
  }) async {
    await ApiService.post(
      '/identity/v1/parents/invitation/$childId/$phoneNumber',
    );
  }

  static Future<List<InvitationDto>> getInvitations() async {
    final token = await AuthTokenService.getToken();

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/identity/v1/parents/invitations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    if (response.body.trim().isEmpty) return [];

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> list;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['content'] is List) {
      list = decoded['content'] as List<dynamic>;
    } else if (decoded is Map && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      return [];
    }

    return list.map((json) {
      return InvitationDto(
        id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
        status: json['status']?.toString() ?? '',
        childFullName: json['childFullName']?.toString() ?? '',
        parentFullName: json['parentFullName']?.toString() ?? '',
      );
    }).toList();
  }

  static Future<void> acceptInvitation(int invitationId) async {
    await ApiService.patch(
      '/identity/v1/parents/invitations/$invitationId/accept',
    );
  }

  static Future<void> declineInvitation(int invitationId) async {
    await ApiService.patch(
      '/identity/v1/parents/invitations/$invitationId/decline',
    );
  }
}
