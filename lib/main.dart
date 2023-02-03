import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

/// The route configuration.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'search',
          builder: (BuildContext context, GoRouterState state) {
            // query params
            final selectedUserId = state.queryParams['user'];
            final selectedUserInfo = state.queryParams['info'];
            return SearchScreen(
                selectedUserId: selectedUserId,
                selectedUserInfo: selectedUserInfo);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => context.go('/search'),
              child: const Text('Go to the Details screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({this.selectedUserInfo, this.selectedUserId, Key? key})
      : super(key: key);
  final String? selectedUserInfo;
  final String? selectedUserId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<dynamic> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: futureUsers,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Details Screen'),
              leading: BackButton(
                onPressed: () => context.go('/'),
              ),
            ),
            body: Center(
                child: snapshot.hasData
                    ? SearchForm(
                        selectedUserId: widget.selectedUserId,
                        selectedUserInfo: widget.selectedUserInfo,
                        users: snapshot.data)
                    : Column(children: [
                        Text(snapshot.connectionState.toString()),
                        const CircularProgressIndicator()
                      ])),
          );
        });
  }
}

class SearchForm extends StatefulWidget {
  const SearchForm(
      {this.selectedUserInfo,
      this.selectedUserId,
      required this.users,
      Key? key})
      : super(key: key);
  final String? selectedUserInfo;
  final String? selectedUserId;
  final List users;
  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _formKey = GlobalKey<FormState>();
  String? _userId;
  String? _userInfo;
  bool _loading = false;
  String? _result;
  @override
  void initState() {
    super.initState();

    if (widget.selectedUserId != null) {
      setState(() {
        _userId = widget.selectedUserId;
      });
    }

    if (widget.selectedUserInfo != null) {
      setState(() {
        _userInfo = widget.selectedUserInfo;
      });
    }

    if (widget.selectedUserInfo != null && widget.selectedUserId != null) {
      handleSearch();
    }
  }

  handleSearch() {
    final Future<String> future = {
      "album": fetchAlbumByUserId(_userId!),
      "todos": fetchTodosByUserId(_userId!),
      "post": fetchPostByUserId(_userId!)
    }[_userInfo]!;
    setState(() {
      _loading = true;
    });

    future.then((value) {
      setState(() {
        _result = value;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    html.window.history
        .pushState({}, '', '/search?user=$_userId&info=$_userInfo');
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButton(
              hint: const Text("Seleccione un usuario"),
              value: _userId,
              items: widget.users
                  .map((user) => DropdownMenuItem(
                        value: user["id"].toString(),
                        child: Text(user["name"]),
                      ))
                  .toList(),
              onChanged: (user) {
                setState(() {
                  _userId = user;
                });
              }),
          DropdownButton(
              hint: const Text("Seleccione un usuario"),
              value: _userInfo,
              items: const [
                DropdownMenuItem(
                  value: "album",
                  child: Text("Album"),
                ),
                DropdownMenuItem(
                  value: "todos",
                  child: Text("Tareas"),
                ),
                DropdownMenuItem(
                  value: "post",
                  child: Text("Publicaciones"),
                )
              ],
              onChanged: (info) {
                setState(() {
                  _userInfo = info;
                });
              }),
          ElevatedButton(
            onPressed: (_userId == null || _userInfo == null || _loading)
                ? null
                : handleSearch,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text("Buscar"),
          ),
          Text(_result ?? "Sin resultado de momento")
        ],
      ),
    );
  }
}

Future<dynamic> fetchUsers() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
  return jsonDecode(response.body);
}

Future<String> fetchAlbumByUserId(String userId) async {
  final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users/$userId/albums'));
  return jsonDecode(response.body).toString();
}

Future<String> fetchTodosByUserId(String userId) async {
  final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users/$userId/todos'));
  return jsonDecode(response.body).toString();
}

Future<String> fetchPostByUserId(String userId) async {
  final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users/$userId/post'));
  return jsonDecode(response.body).toString();
}
