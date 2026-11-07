class CropInputParams {
  final String soilType; // 'black_soil', 'alluvial', 'red_soil', 'sandy_loam', 'clay_loam'
  final double landAreaAcres;
  final String season; // 'kharif', 'rabi', 'zaid'
  final String waterSource; // 'tube_well', 'canal', 'rainfed', 'drip_sprinkler'
  final String district;
  final String state;
  final double latitude;
  final double longitude;

  const CropInputParams({
    required this.soilType,
    required this.landAreaAcres,
    required this.season,
    required this.waterSource,
    this.district = 'सीहोर',
    this.state = 'मध्य प्रदेश',
    this.latitude = 23.2032,
    this.longitude = 77.0844,
  });

  Map<String, dynamic> toJson() {
    return {
      'soil_type': soilType,
      'land_area_acres': landAreaAcres,
      'season': season,
      'water_source': waterSource,
      'district': district,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
