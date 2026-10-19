import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/world_states_model.dart';
import '../models/countries_list_model.dart';
import '../../utils/app_url.dart';

/// Service class for fetching COVID-19 data from the API.
class ApiService {
  /// Fetches global COVID-19 statistics.
  Future<WorldStatesModel> fetchWorldRecords() async {
    try {
      final response = await http.get(Uri.parse(AppUrl.worldStatesApi));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorldStatesModel.fromJson(data);
      } else {
        throw Exception(
            'Failed to fetch world records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching world records: $e');
    }
  }

  /// Fetches the list of countries with COVID-19 statistics.
  Future<List<CountriesListModel>> fetchCountriesList() async {
    try {
      final response = await http.get(Uri.parse(AppUrl.countriesList));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            'Countries List API Response: $data'); // Debug: Log the raw response
        return data.map((json) => CountriesListModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch countries list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching countries list: $e');
    }
  }
}
