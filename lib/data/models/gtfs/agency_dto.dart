import '../../../domain/entities/agency_entity.dart';

/// Data Transfer Object for GTFS agency.txt file
/// 
/// Represents a transit agency or brand that operates transit services.
/// This DTO parses CSV data from agency.txt and converts it to an AgencyEntity.
class AgencyDto {
  /// Identifies a transit brand which is often synonymous with a transit agency.
  /// Conditionally required: Required when dataset contains multiple agencies.
  final String? id;
  
  /// Full name of the transit agency (required).
  final String name;
  
  /// URL of the transit agency (required).
  final String url;
  
  /// Timezone where the transit agency is located (required).
  /// All agencies in a dataset must have the same timezone.
  final String timezone;
  
  /// Primary language used by this transit agency (optional).
  /// Helps GTFS consumers choose capitalization rules and language-specific settings.
  final String? lang;
  
  /// Voice telephone number for the specified agency (optional).
  /// May contain punctuation marks to group digits.
  final String? phone;
  
  /// URL of a web page where riders can purchase tickets or fare instruments (optional).
  final String? fareUrl;
  
  /// Email address actively monitored by the agency's customer service department (optional).
  final String? email;
  
  /// Indicates if riders can access transit service using contactless EMV cards (optional).
  /// Valid values: 0 or empty (no info), 1 (supported), 2 (not supported).
  final int? cemvSupport;

  AgencyDto({
    this.id,
    required this.name,
    required this.url,
    required this.timezone,
    this.lang,
    this.phone,
    this.fareUrl,
    this.email,
    this.cemvSupport,
  });

  /// Creates an AgencyDto from a CSV row map
  /// 
  /// Parses the CSV fields according to GTFS specification.
  factory AgencyDto.fromCsv(Map<String, String> row) {
    return AgencyDto(
      id: row['agency_id'],
      name: row['agency_name'] ?? '',
      url: row['agency_url'] ?? '',
      timezone: row['agency_timezone'] ?? '',
      lang: row['agency_lang'],
      phone: row['agency_phone'],
      fareUrl: row['agency_fare_url'],
      email: row['agency_email'],
      cemvSupport: row['cemv_support'] != null
          ? int.tryParse(row['cemv_support']!)
          : null,
    );
  }

  /// Converts this DTO to an AgencyEntity
  /// 
  /// Transforms the data transfer object into a domain entity.
  AgencyEntity toEntity() {
    return AgencyEntity(
      id: id,
      name: name,
      url: url,
      timezone: timezone,
      lang: lang,
      phone: phone,
      fareUrl: fareUrl,
      email: email,
      cemvSupport: cemvSupport,
    );
  }
}

