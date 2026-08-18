import 'coordinates.dart';

/// Geocode result model
class GeocodeResult {
  final String address;
  final LatLng coordinates;
  final Map<String, dynamic> components;
  final String formattedAddress;
  final double confidence;
  final String source;

  GeocodeResult({
    required this.address,
    required this.coordinates,
    required this.components,
    required this.formattedAddress,
    required this.confidence,
    required this.source,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    return GeocodeResult(
      address: json['address'] ?? '',
      coordinates: LatLng(
        (json['coordinates']['latitude'] ?? 0.0).toDouble(),
        (json['coordinates']['longitude'] ?? 0.0).toDouble(),
      ),
      components: json['components'] ?? {},
      formattedAddress: json['formattedAddress'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'components': components,
      'formattedAddress': formattedAddress,
      'confidence': confidence,
      'source': source,
    };
  }
}

/// Reverse geocode result model
class ReverseGeocodeResult {
  final LatLng coordinates;
  final String address;
  final Map<String, dynamic> components;
  final String formattedAddress;
  final double confidence;

  ReverseGeocodeResult({
    required this.coordinates,
    required this.address,
    required this.components,
    required this.formattedAddress,
    required this.confidence,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      coordinates: LatLng(
        (json['coordinates']['latitude'] ?? 0.0).toDouble(),
        (json['coordinates']['longitude'] ?? 0.0).toDouble(),
      ),
      address: json['address'] ?? '',
      components: json['components'] ?? {},
      formattedAddress: json['formattedAddress'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'address': address,
      'components': components,
      'formattedAddress': formattedAddress,
      'confidence': confidence,
    };
  }
}

/// Route result model
class RouteResult {
  final List<LatLng> coordinates;
  final List<RouteStep> steps;
  final RouteSummary summary;
  final Map<String, dynamic> metadata;

  RouteResult({
    required this.coordinates,
    required this.steps,
    required this.summary,
    required this.metadata,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((coord) => LatLng(coord['latitude'], coord['longitude']))
          .toList() ?? [],
      steps: (json['steps'] as List<dynamic>?)
          ?.map((step) => RouteStep.fromJson(step))
          .toList() ?? [],
      summary: RouteSummary.fromJson(json['summary'] ?? {}),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates.map((coord) => {
        'latitude': coord.latitude,
        'longitude': coord.longitude,
      }).toList(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'summary': summary.toJson(),
      'metadata': metadata,
    };
  }
}

/// Route step model
class RouteStep {
  final String instruction;
  final double distance;
  final Duration duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: Duration(seconds: json['duration'] ?? 0),
      startLocation: LatLng(
        (json['startLocation']['latitude'] ?? 0.0).toDouble(),
        (json['startLocation']['longitude'] ?? 0.0).toDouble(),
      ),
      endLocation: LatLng(
        (json['endLocation']['latitude'] ?? 0.0).toDouble(),
        (json['endLocation']['longitude'] ?? 0.0).toDouble(),
      ),
      maneuver: json['maneuver'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration.inSeconds,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
      'maneuver': maneuver,
    };
  }
}

/// Route summary model
class RouteSummary {
  final double totalDistance;
  final Duration totalDuration;
  final double tollCost;
  final String currency;
  final List<String> warnings;

  RouteSummary({
    required this.totalDistance,
    required this.totalDuration,
    required this.tollCost,
    required this.currency,
    required this.warnings,
  });

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      totalDuration: Duration(seconds: json['totalDuration'] ?? 0),
      tollCost: (json['tollCost'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'ZAR',
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalDuration': totalDuration.inSeconds,
      'tollCost': tollCost,
      'currency': currency,
      'warnings': warnings,
    };
  }
}

/// Place result model
class PlaceResult {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String type;
  final double rating;
  final Map<String, dynamic> details;

  PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    required this.rating,
    required this.details,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      type: json['type'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      details: json['details'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'type': type,
      'rating': rating,
      'details': details,
    };
  }
}

/// Place details model
class PlaceDetails {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String phone;
  final String website;
  final double rating;
  final int reviewCount;
  final List<String> photos;
  final Map<String, dynamic> hours;
  final Map<String, dynamic> reviews;
  final Map<String, dynamic> metadata;

  PlaceDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.phone,
    required this.website,
    required this.rating,
    required this.reviewCount,
    required this.photos,
    required this.hours,
    required this.reviews,
    required this.metadata,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      photos: List<String>.from(json['photos'] ?? []),
      hours: json['hours'] ?? {},
      reviews: json['reviews'] ?? {},
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'phone': phone,
      'website': website,
      'rating': rating,
      'reviewCount': reviewCount,
      'photos': photos,
      'hours': hours,
      'reviews': reviews,
      'metadata': metadata,
    };
  }
}

/// Nearby place model
class NearbyPlace {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String type;
  final double distance;
  final double rating;
  final Map<String, dynamic> details;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    required this.distance,
    required this.rating,
    required this.details,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      type: json['type'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      details: json['details'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'type': type,
      'distance': distance,
      'rating': rating,
      'details': details,
    };
  }
}

/// Address validation model
class AddressValidation {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? suggestions;
  final Map<String, dynamic>? correctedAddress;

  AddressValidation({
    required this.isValid,
    this.errorMessage,
    this.suggestions,
    this.correctedAddress,
  });

  factory AddressValidation.fromJson(Map<String, dynamic> json) {
    return AddressValidation(
      isValid: json['isValid'] ?? false,
      errorMessage: json['errorMessage'],
      suggestions: json['suggestions'],
      correctedAddress: json['correctedAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errorMessage': errorMessage,
      'suggestions': suggestions,
      'correctedAddress': correctedAddress,
    };
  }
}

/// Distance matrix model
class DistanceMatrix {
  final List<DistanceMatrixElement> elements;
  final List<String> origins;
  final List<String> destinations;
  final String status;

  DistanceMatrix({
    required this.elements,
    required this.origins,
    required this.destinations,
    required this.status,
  });

  factory DistanceMatrix.fromJson(Map<String, dynamic> json) {
    return DistanceMatrix(
      elements: (json['elements'] as List<dynamic>?)
          ?.map((element) => DistanceMatrixElement.fromJson(element))
          .toList() ?? [],
      origins: List<String>.from(json['origins'] ?? []),
      destinations: List<String>.from(json['destinations'] ?? []),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'elements': elements.map((element) => element.toJson()).toList(),
      'origins': origins,
      'destinations': destinations,
      'status': status,
    };
  }
}

/// Distance matrix element model
class DistanceMatrixElement {
  final DistanceValue distance;
  final DurationValue duration;
  final String status;

  DistanceMatrixElement({
    required this.distance,
    required this.duration,
    required this.status,
  });

  factory DistanceMatrixElement.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixElement(
      distance: DistanceValue.fromJson(json['distance'] ?? {}),
      duration: DurationValue.fromJson(json['duration'] ?? {}),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance.toJson(),
      'duration': duration.toJson(),
      'status': status,
    };
  }
}

/// Distance value model
class DistanceValue {
  final double value; // in meters
  final String text;

  DistanceValue({
    required this.value,
    required this.text,
  });

  factory DistanceValue.fromJson(Map<String, dynamic> json) {
    return DistanceValue(
      value: (json['value'] ?? 0.0).toDouble(),
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'text': text,
    };
  }
}

/// Duration value model
class DurationValue {
  final int value; // in seconds
  final String text;

  DurationValue({
    required this.value,
    required this.text,
  });

  factory DurationValue.fromJson(Map<String, dynamic> json) {
    return DurationValue(
      value: json['value'] ?? 0,
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'text': text,
    };
  }
}

/// Detailed directions model
class DetailedDirections {
  final List<RouteLeg> legs;
  final RouteSummary summary;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  DetailedDirections({
    required this.legs,
    required this.summary,
    required this.warnings,
    required this.metadata,
  });

  factory DetailedDirections.fromJson(Map<String, dynamic> json) {
    return DetailedDirections(
      legs: (json['legs'] as List<dynamic>?)
          ?.map((leg) => RouteLeg.fromJson(leg))
          .toList() ?? [],
      summary: RouteSummary.fromJson(json['summary'] ?? {}),
      warnings: List<String>.from(json['warnings'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legs': legs.map((leg) => leg.toJson()).toList(),
      'summary': summary.toJson(),
      'warnings': warnings,
      'metadata': metadata,
    };
  }
}

/// Route leg model
class RouteLeg {
  final List<RouteStep> steps;
  final DistanceValue distance;
  final DurationValue duration;
  final String startAddress;
  final String endAddress;
  final LatLng startLocation;
  final LatLng endLocation;

  RouteLeg({
    required this.steps,
    required this.distance,
    required this.duration,
    required this.startAddress,
    required this.endAddress,
    required this.startLocation,
    required this.endLocation,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    return RouteLeg(
      steps: (json['steps'] as List<dynamic>?)
          ?.map((step) => RouteStep.fromJson(step))
          .toList() ?? [],
      distance: DistanceValue.fromJson(json['distance'] ?? {}),
      duration: DurationValue.fromJson(json['duration'] ?? {}),
      startAddress: json['startAddress'] ?? '',
      endAddress: json['endAddress'] ?? '',
      startLocation: LatLng(
        (json['startLocation']['latitude'] ?? 0.0).toDouble(),
        (json['startLocation']['longitude'] ?? 0.0).toDouble(),
      ),
      endLocation: LatLng(
        (json['endLocation']['latitude'] ?? 0.0).toDouble(),
        (json['endLocation']['longitude'] ?? 0.0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((step) => step.toJson()).toList(),
      'distance': distance.toJson(),
      'duration': duration.toJson(),
      'startAddress': startAddress,
      'endAddress': endAddress,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
    };
  }
}

/// Service area model
class ServiceArea {
  final List<LatLng> boundaries;
  final List<String> cities;
  final double radius;
  final LatLng center;
  final Map<String, dynamic> restrictions;

  ServiceArea({
    required this.boundaries,
    required this.cities,
    required this.radius,
    required this.center,
    required this.restrictions,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      boundaries: (json['boundaries'] as List<dynamic>?)
          ?.map((boundary) => LatLng(boundary['latitude'], boundary['longitude']))
          .toList() ?? [],
      cities: List<String>.from(json['cities'] ?? []),
      radius: (json['radius'] ?? 0.0).toDouble(),
      center: LatLng(
        (json['center']['latitude'] ?? 0.0).toDouble(),
        (json['center']['longitude'] ?? 0.0).toDouble(),
      ),
      restrictions: json['restrictions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boundaries': boundaries.map((boundary) => {
        'latitude': boundary.latitude,
        'longitude': boundary.longitude,
      }).toList(),
      'cities': cities,
      'radius': radius,
      'center': {
        'latitude': center.latitude,
        'longitude': center.longitude,
      },
      'restrictions': restrictions,
    };
  }
}

/// Service area check model
class ServiceAreaCheck {
  final bool isWithinArea;
  final double distance;
  final LatLng nearestPoint;
  final String message;

  ServiceAreaCheck({
    required this.isWithinArea,
    required this.distance,
    required this.nearestPoint,
    required this.message,
  });

  factory ServiceAreaCheck.fromJson(Map<String, dynamic> json) {
    return ServiceAreaCheck(
      isWithinArea: json['isWithinArea'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
      nearestPoint: LatLng(
        (json['nearestPoint']['latitude'] ?? 0.0).toDouble(),
        (json['nearestPoint']['longitude'] ?? 0.0).toDouble(),
      ),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isWithinArea': isWithinArea,
      'distance': distance,
      'nearestPoint': {
        'latitude': nearestPoint.latitude,
        'longitude': nearestPoint.longitude,
      },
      'message': message,
    };
  }
}

/// Traffic info model
class TrafficInfo {
  final List<TrafficIncident> incidents;
  final Map<String, TrafficFlow> flows;
  final DateTime lastUpdated;

  TrafficInfo({
    required this.incidents,
    required this.flows,
    required this.lastUpdated,
  });

  factory TrafficInfo.fromJson(Map<String, dynamic> json) {
    return TrafficInfo(
      incidents: (json['incidents'] as List<dynamic>?)
          ?.map((incident) => TrafficIncident.fromJson(incident))
          .toList() ?? [],
      flows: (json['flows'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, TrafficFlow.fromJson(value))) ?? {},
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidents': incidents.map((incident) => incident.toJson()).toList(),
      'flows': flows.map((key, flow) => MapEntry(key, flow.toJson())),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Traffic incident model
class TrafficIncident {
  final String id;
  final String type;
  final String description;
  final LatLng location;
  final DateTime startTime;
  final DateTime? endTime;
  final int severity;
  final Duration delay;

  TrafficIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.startTime,
    this.endTime,
    required this.severity,
    required this.delay,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    return TrafficIncident(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      location: LatLng(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      ),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      severity: json['severity'] ?? 1,
      delay: Duration(minutes: json['delay'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'severity': severity,
      'delay': delay.inMinutes,
    };
  }
}

/// Traffic flow model
class TrafficFlow {
  final String roadName;
  final int speed;
  final int freeFlowSpeed;
  final int confidence;
  final String color;

  TrafficFlow({
    required this.roadName,
    required this.speed,
    required this.freeFlowSpeed,
    required this.confidence,
    required this.color,
  });

  factory TrafficFlow.fromJson(Map<String, dynamic> json) {
    return TrafficFlow(
      roadName: json['roadName'] ?? '',
      speed: json['speed'] ?? 0,
      freeFlowSpeed: json['freeFlowSpeed'] ?? 0,
      confidence: json['confidence'] ?? 0,
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roadName': roadName,
      'speed': speed,
      'freeFlowSpeed': freeFlowSpeed,
      'confidence': confidence,
      'color': color,
    };
  }
}
