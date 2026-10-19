import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/services/api_service.dart';
import 'detail_screen.dart';
import '../../data/models/countries_list_model.dart';

/// Screen displaying a searchable list of countries with COVID-19 statistics.
class CountriesListScreen extends StatefulWidget {
  const CountriesListScreen({Key? key}) : super(key: key);

  @override
  _CountriesListScreenState createState() => _CountriesListScreenState();
}

class _CountriesListScreenState extends State<CountriesListScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();
  Timer? _debounce;

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: const Text('Countries'),
      backgroundColor: Colors.blue, // Optional: Customize the AppBar color
    ),
    body : SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                hintText: 'Search with country name',
                suffixIcon: searchController.text.isEmpty
                    ? const Icon(Icons.search)
                    : GestureDetector(
                        onTap: () {
                          searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.clear),
                      ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CountriesListModel>>(
              future: apiService.fetchCountriesList(),
              builder: (context, AsyncSnapshot<List<CountriesListModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade700,
                        highlightColor: Colors.grey.shade100,
                        child: ListTile(
                          leading: Container(height: 50, width: 50, color: Colors.white),
                          title: Container(
                            width: 100,
                            height: 8.0,
                            color: Colors.white,
                          ),
                          subtitle: Container(
                            width: double.infinity,
                            height: 8.0,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  final countries = snapshot.data!;
                  return ListView.builder(
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final name = country.country.toLowerCase();
                      final searchQuery = searchController.text.toLowerCase();
                      if (searchQuery.isEmpty || name.contains(searchQuery)) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      image: country.countryInfo.flag,
                                      name: country.country,
                                      totalCases: country.cases,
                                      totalRecovered: country.recovered,
                                      totalDeaths: country.deaths,
                                      active: country.active,
                                      critical: country.critical,
                                      todayRecovered: country.todayRecovered,
                                      test: country.tests,
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: Image(
                                  height: 50,
                                  width: 50,
                                  image: NetworkImage(country.countryInfo.flag),
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                                title: Text(country.country),
                                subtitle: Text("Cases: ${country.cases}"),
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      } else {
                        return Container();
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    )
    );
  }
}