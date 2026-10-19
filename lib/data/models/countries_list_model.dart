/// Model class for country-specific COVID-19 statistics.
class CountriesListModel {
  final int updated;
  final String country;
  final CountryInfo countryInfo;
  final int cases;
  final int todayCases;
  final int deaths;
  final int todayDeaths;
  final int recovered;
  final int todayRecovered;
  final int active;
  final int critical;
  final double casesPerOneMillion; // Changed to double
  final double deathsPerOneMillion; // Already double
  final int tests;
  final double testsPerOneMillion; // Already double
  final int population;
  final String continent;
  final int oneCasePerPeople;
  final int oneDeathPerPeople;
  final int oneTestPerPeople;
  final double activePerOneMillion; // Already double
  final double recoveredPerOneMillion; // Already double
  final double criticalPerOneMillion; // Already double

  CountriesListModel({
    required this.updated,
    required this.country,
    required this.countryInfo,
    required this.cases,
    required this.todayCases,
    required this.deaths,
    required this.todayDeaths,
    required this.recovered,
    required this.todayRecovered,
    required this.active,
    required this.critical,
    required this.casesPerOneMillion,
    required this.deathsPerOneMillion,
    required this.tests,
    required this.testsPerOneMillion,
    required this.population,
    required this.continent,
    required this.oneCasePerPeople,
    required this.oneDeathPerPeople,
    required this.oneTestPerPeople,
    required this.activePerOneMillion,
    required this.recoveredPerOneMillion,
    required this.criticalPerOneMillion,
  });

  factory CountriesListModel.fromJson(Map<String, dynamic> json) {
    return CountriesListModel(
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      country: json['country'] ?? '',
      countryInfo: CountryInfo.fromJson(json['countryInfo'] ?? {}),
      cases: (json['cases'] as num?)?.toInt() ?? 0,
      todayCases: (json['todayCases'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      todayDeaths: (json['todayDeaths'] as num?)?.toInt() ?? 0,
      recovered: (json['recovered'] as num?)?.toInt() ?? 0,
      todayRecovered: (json['todayRecovered'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      critical: (json['critical'] as num?)?.toInt() ?? 0,
      casesPerOneMillion: (json['casesPerOneMillion'] as num?)?.toDouble() ?? 0.0,
      deathsPerOneMillion: (json['deathsPerOneMillion'] as num?)?.toDouble() ?? 0.0,
      tests: (json['tests'] as num?)?.toInt() ?? 0,
      testsPerOneMillion: (json['testsPerOneMillion'] as num?)?.toDouble() ?? 0.0,
      population: (json['population'] as num?)?.toInt() ?? 0,
      continent: json['continent'] ?? '',
      oneCasePerPeople: (json['oneCasePerPeople'] as num?)?.toInt() ?? 0,
      oneDeathPerPeople: (json['oneDeathPerPeople'] as num?)?.toInt() ?? 0,
      oneTestPerPeople: (json['oneTestPerPeople'] as num?)?.toInt() ?? 0,
      activePerOneMillion: (json['activePerOneMillion'] as num?)?.toDouble() ?? 0.0,
      recoveredPerOneMillion: (json['recoveredPerOneMillion'] as num?)?.toDouble() ?? 0.0,
      criticalPerOneMillion: (json['criticalPerOneMillion'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updated': updated,
      'country': country,
      'countryInfo': countryInfo.toJson(),
      'cases': cases,
      'todayCases': todayCases,
      'deaths': deaths,
      'todayDeaths': todayDeaths,
      'recovered': recovered,
      'todayRecovered': todayRecovered,
      'active': active,
      'critical': critical,
      'casesPerOneMillion': casesPerOneMillion,
      'deathsPerOneMillion': deathsPerOneMillion,
      'tests': tests,
      'testsPerOneMillion': testsPerOneMillion,
      'population': population,
      'continent': continent,
      'oneCasePerPeople': oneCasePerPeople,
      'oneDeathPerPeople': oneDeathPerPeople,
      'oneTestPerPeople': oneTestPerPeople,
      'activePerOneMillion': activePerOneMillion,
      'recoveredPerOneMillion': recoveredPerOneMillion,
      'criticalPerOneMillion': criticalPerOneMillion,
    };
  }
}

/// Nested model for country-specific information.
class CountryInfo {
  final int id;
  final String iso2;
  final String iso3;
  final double lat; // Changed to double
  final double long; // Changed to double
  final String flag;

  CountryInfo({
    required this.id,
    required this.iso2,
    required this.iso3,
    required this.lat,
    required this.long,
    required this.flag,
  });

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      id: (json['_id'] as num?)?.toInt() ?? 0,
      iso2: json['iso2'] ?? '',
      iso3: json['iso3'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0, // Safe conversion
      long: (json['long'] as num?)?.toDouble() ?? 0.0, // Safe conversion
      flag: json['flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'iso2': iso2,
      'iso3': iso3,
      'lat': lat,
      'long': long,
      'flag': flag,
    };
  }
}