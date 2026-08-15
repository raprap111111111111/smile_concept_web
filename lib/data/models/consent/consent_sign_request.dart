class ConsentSignRequest {
  final int consentTemplateId;
  final int userId;
  final int? appointmentId;
  final String signatureData;
  final Map<String, dynamic>? formData;    
  final String? signOnBehalfOf;                

  const ConsentSignRequest({
    required this.consentTemplateId,
    required this.userId,
    this.appointmentId,
    required this.signatureData,
    this.formData,
    this.signOnBehalfOf,
  });

  Map<String, dynamic> toJson() => {
        'consent_template_id': consentTemplateId,
        'user_id': userId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        'signature_data': signatureData,
        if (formData != null) 'form_data': formData,
        if (signOnBehalfOf != null) 'sign_on_behalf_of': signOnBehalfOf,
      };
}