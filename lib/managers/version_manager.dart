import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';

class VersionManager {
  VersionManager._();

  static final VersionManager _instance = VersionManager._();

  static VersionManager get instance => _instance;

  factory VersionManager() => _instance;

  Future<Version?> getLatestRelease() async {
    try {
      final response = await get(
        Uri.parse(
          'https://api.github.com/repos/SaadArdati/pocket_gpt/releases/latest',
        ),
      );

      if (response.statusCode != 200) {
        throw response.body;
      }

      final data = jsonDecode(response.body);
      return Version.parse(data['tag_name'].toString());
    } catch (error, stackTrace) {
      log(error.toString());
      log(stackTrace.toString());
      return null;
    }
  }
}
