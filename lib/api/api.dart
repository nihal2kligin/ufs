import 'dart:convert';
import 'package:http/http.dart' as http;

Future getWeather(double latitude, double longitude) async {
  var url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true');
  print(url.toString());

  http.Response response = await http.get(
    url,
    headers: {"content-type": "application/json"},
  );
  try {
    if (response.statusCode == 200) {
      String data = utf8.decode(response.bodyBytes);
      var decodedData = jsonDecode(data);
      return decodedData;
    } else {
      return 'failed';
    }
  } catch (e) {
    return 'failed';
  }
}
