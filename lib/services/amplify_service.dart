import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../amplifyconfiguration.dart';

class AmplifyService {

  static Future<void> configure() async {
    try {
      await Amplify.addPlugin(AmplifyAPI());
      await Amplify.configure(amplifyconfig);
      safePrint("Amplify ready");
    } catch (e) {
      safePrint(e);
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      const String query = '''
query Login(\$email: String!) {
  listClients(filter: { email: { eq: \$email } }) {
    items {
      vendorID
      email
      password
      companyName
      deviceCount
    }
  }
}
''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {
          "email": email,
        },
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) return null;

      final data = jsonDecode(response.data!);
      final items = data['listClients']['items'];

      if (items == null || items.isEmpty) return null;

      final user = items[0];

      // Password check
      if (user['password'] != password) return null;

      // ✅ Return full client object
      return user;

    } catch (e) {
      safePrint("Login error: $e");
      return null;
    }
  }

}
