import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kamus Beser',
      home: InfinityScroll(),
    );
  }
}

class InfinityScroll extends StatefulWidget {
  @override
  _InfinityScrollState createState() => _InfinityScrollState();
}

class _InfinityScrollState extends State<InfinityScroll> {
  List _data = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _searching = false;
  TextEditingController _searchController = TextEditingController();

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http
        .get(Uri.parse('http://127.0.0.1:8000/api/beser?page=$_currentPage'));

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

    Uri url = Uri.parse('http://127.0.0.1:8000/api/beser/search');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String body = jsonEncode({'word': query});
    http.Response response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      setState(() {
        _data = json.decode(response.body);
        _isLoading = false;
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
            ? const Text('Kamus Beser')
            : TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                    hintText: "Cari kata..",
                    hintStyle: TextStyle(color: Colors.grey))),
        actions: [
          IconButton(
              onPressed: () async {
                String query = _searchController.text;
                setState(() {
                  _searching = !_searching;
                });
                query.isEmpty ? await _refreshData() : await _searchData(query);
              },
              icon: Icon(Icons.search, color: Colors.white)),
        ],
      ),
      body: Column(
        children: [
          if (_data.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 150.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Data tidak ditemukan",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: Text("Refresh"),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
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
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 50.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(_data[index]['indonesia']),
                      subtitle: Text(_data[index]['beser']),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
