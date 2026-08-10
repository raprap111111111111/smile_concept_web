class ConsentSignRequest {
  final int consentTemplateId;
  final int userId;
  final int? appointmentId;
  final String signatureData;

  const ConsentSignRequest({
    required this.consentTemplateId,
    required this.userId,
    this.appointmentId,
    required this.signatureData,
  });

  Map<String, dynamic> toJson() => {
        'consent_template_id': consentTemplateId,
        'user_id': userId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        'signature_data': signatureData,
      };
}