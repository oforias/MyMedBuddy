import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const commonDrugs = ['aspirin', 'acetaminophen', 'ibuprofen', 'omeprazole'];

final healthTipProvider = FutureProvider<String>((ref) async {
  final shuffledDrugs = List<String>.from(commonDrugs)..shuffle();
  for (var i = 0; i < shuffledDrugs.length; i++) {
    final drug = shuffledDrugs[i];
    final url = Uri.parse(
      'https://api.fda.gov/drug/label.json?search=active_ingredient:$drug&limit=1',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final purpose = (result['purpose'] as List?)?.join(' ') ?? '';
        final indications =
            (result['indications_and_usage'] as List?)?.join(' ') ?? '';
        final warning = (result['warnings'] as List?)?.join(' ') ?? '';
        return 'Drug: $drug\nPurpose: $purpose\nUsage: $indications\nWarning: $warning';
      }
    }
  }
  // Fallback message
  return 'No drug information available right now. Please try again later or search for a specific drug.';
});
