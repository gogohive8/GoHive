// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   static const String baseUrl = 'http://localhost:3000/api';
//   String? _token;

//   void setToken(String token) {
//     _token = token;
//   }

//   Future<void> signUp(String username, String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/users'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'username': username, 'email': email, 'password': password}),
//     );
//     if (response.statusCode != 201) {
//       throw Exception('Failed to sign up: ${response.body}');
//     }
//   }

//   Future<String> login(String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/login'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//     if (response.statusCode == 200) {
//       final token = jsonDecode(response.body)['token'];
//       setToken(token);
//       return token;
//     } else {
//       throw Exception('Failed to login: ${response.body}');
//     }
//   }

//   Future<List<dynamic>> getProducts() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/products'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $_token',
//       },
//     );
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Failed to load products: ${response.body}');
//     }
//   }

//   Future<void> logout() async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/logout'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $_token',
//       },
//     );
//     if (response.statusCode != 200) {
//       throw Exception('Failed to logout: ${response.body}');
//     }
//     _token = null;
//   }
// }
