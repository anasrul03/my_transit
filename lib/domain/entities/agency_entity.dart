import 'package:equatable/equatable.dart';

/// Domain entity representing a transit agency from GTFS agency.txt
/// 
/// Represents a transit brand or agency that operates transit services.
/// This entity is used throughout the domain layer for agency-related operations.
class AgencyEntity extends Equatable {
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

  const AgencyEntity({
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

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        timezone,
        lang,
        phone,
        fareUrl,
        email,
        cemvSupport,
      ];
}

