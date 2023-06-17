import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const Kamus());

class Kamus extends StatelessWidget {
  const Kamus({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Kamus Beser',
      home: InfinityScroll(),
    );
  }
}

class InfinityScroll extends StatefulWidget {
  const InfinityScroll({Key? key}) : super(key: key);
  @override
  _InfinityScrollState createState() => _InfinityScrollState();
}

class _InfinityScrollState extends State<InfinityScroll> {
  List _data = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://nawproject.000webhostapp.com/public/api/beser?page=$_currentPage'));

    if (response.statusCode == 200) {
      setState(() {
        _data.addAll(json.decode(response.body)['data']);
        _isLoading = false;
        _currentPage++;
      });
    } else {
      throw Exception('Gagal memuat data.');
    }
  }

  Future<void> _searchData(String query) async {
    setState(() {
      _isLoading = true;
    });

    Uri url = Uri.parse(
        'https://nawproject.000webhostapp.com/public/api/beser/search');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String body = jsonEncode({'word': query});
    http.Response response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      setState(() {
        _isLoading = false;
        _data = json.decode(response.body);
      });
    } else {
      throw Exception('Gagal memuat data.');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _data.clear();
      _currentPage = 1;
    });
    await _fetchData();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_searching
            ? const Text(
                'Kamus Beser',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              )
            : TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: "Cari kata..",
                  hintStyle: TextStyle(color: Color.fromARGB(255, 73, 73, 73)),
                ),
                cursorColor: const Color.fromARGB(255, 73, 73, 73),
              ),
        actions: [
          IconButton(
            onPressed: () async {
              String query = _searchController.text;
              setState(() {
                _searching = !_searching;
              });
              if (query.isEmpty) {
                await _refreshData();
              } else {
                await _searchData(query);
              }
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: _data.isEmpty
          ? Center(
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 150.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Data tidak ditemukan",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            ))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoading &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                    _fetchData();
                  }
                  return true;
                },
                child: ListView.builder(
                  itemCount: _data.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == _data.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 50.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(
                        _data[index]['indonesia'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        _data[index]['beser'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
