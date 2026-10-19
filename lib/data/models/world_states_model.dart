/// Model class for global COVID-19 statistics.
class WorldStatesModel {
  final int updated;
  final int cases;
  final int todayCases;
  final int deaths;
  final int todayDeaths;
  final int recovered;
  final int todayRecovered;
  final int active;
  final int critical;
  final int casesPerOneMillion;
  final double deathsPerOneMillion;
  final int tests;
  final double testsPerOneMillion;
  final int population;
  final int oneCasePerPeople;
  final int oneDeathPerPeople;
  final int oneTestPerPeople;
  final double activePerOneMillion;
  final double recoveredPerOneMillion;
  final double criticalPerOneMillion;
  final int affectedCountries;

  WorldStatesModel({
    required this.updated,
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
    required this.oneCasePerPeople,
    required this.oneDeathPerPeople,
    required this.oneTestPerPeople,
    required this.activePerOneMillion,
    required this.recoveredPerOneMillion,
    required this.criticalPerOneMillion,
    required this.affectedCountries,
  });

  factory WorldStatesModel.fromJson(Map<String, dynamic> json) {
    return WorldStatesModel(
      updated: json['updated'] ?? 0,
      cases: json['cases'] ?? 0,
      todayCases: json['todayCases'] ?? 0,
      deaths: json['deaths'] ?? 0,
      todayDeaths: json['todayDeaths'] ?? 0,
      recovered: json['recovered'] ?? 0,
      todayRecovered: json['todayRecovered'] ?? 0,
      active: json['active'] ?? 0,
      critical: json['critical'] ?? 0,
      casesPerOneMillion: json['casesPerOneMillion'] ?? 0,
      deathsPerOneMillion: (json['deathsPerOneMillion'] ?? 0).toDouble(),
      tests: json['tests'] ?? 0,
      testsPerOneMillion: (json['testsPerOneMillion'] ?? 0).toDouble(),
      population: json['population'] ?? 0,
      oneCasePerPeople: json['oneCasePerPeople'] ?? 0,
      oneDeathPerPeople: json['oneDeathPerPeople'] ?? 0,
      oneTestPerPeople: json['oneTestPerPeople'] ?? 0,
      activePerOneMillion: (json['activePerOneMillion'] ?? 0).toDouble(),
      recoveredPerOneMillion: (json['recoveredPerOneMillion'] ?? 0).toDouble(),
      criticalPerOneMillion: (json['criticalPerOneMillion'] ?? 0).toDouble(),
      affectedCountries: json['affectedCountries'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updated': updated,
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
      'oneCasePerPeople': oneCasePerPeople,
      'oneDeathPerPeople': oneDeathPerPeople,
      'oneTestPerPeople': oneTestPerPeople,
      'activePerOneMillion': activePerOneMillion,
      'recoveredPerOneMillion': recoveredPerOneMillion,
      'criticalPerOneMillion': criticalPerOneMillion,
      'affectedCountries': affectedCountries,
    };
  }
}