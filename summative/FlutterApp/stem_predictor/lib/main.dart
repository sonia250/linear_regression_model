import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Women in STEM Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E24AA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const PredictorPage(),
    );
  }
}

class PredictorPage extends StatefulWidget {
  const PredictorPage({super.key});

  @override
  State<PredictorPage> createState() => _PredictorPageState();
}

class _PredictorPageState extends State<PredictorPage> {
  final _enrollmentController = TextEditingController();
  final _genderGapController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedStemField = 'Engineering';
  final List<String> _stemFields = ['Biology', 'Engineering', 'Mathematics', 'Physics'];

  String _resultText = '';
  bool _isLoading = false;
  bool _hasError = false;

  static const String _apiUrl =
      'https://linear-regression-model-y4xx.onrender.com/predict';

  Future<void> _predict() async {
    // Validate inputs
    if (_enrollmentController.text.isEmpty ||
        _genderGapController.text.isEmpty ||
        _yearController.text.isEmpty) {
      setState(() {
        _resultText = '⚠️ Please fill in all fields before predicting.';
        _hasError = true;
      });
      return;
    }

    final enrollment = double.tryParse(_enrollmentController.text);
    final genderGap = double.tryParse(_genderGapController.text);
    final year = int.tryParse(_yearController.text);

    if (enrollment == null || genderGap == null || year == null) {
      setState(() {
        _resultText = '⚠️ Please enter valid numbers in all fields.';
        _hasError = true;
      });
      return;
    }

    if (enrollment < 0 || enrollment > 100) {
      setState(() {
        _resultText = '⚠️ Female Enrollment must be between 0 and 100.';
        _hasError = true;
      });
      return;
    }

    if (genderGap < 0 || genderGap > 1) {
      setState(() {
        _resultText = '⚠️ Gender Gap Index must be between 0.0 and 1.0.';
        _hasError = true;
      });
      return;
    }

    if (year < 2000 || year > 2030) {
      setState(() {
        _resultText = '⚠️ Year must be between 2000 and 2030.';
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = '';
      _hasError = false;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'female_enrollment': enrollment,
          'gender_gap_index': genderGap,
          'stem_field': _selectedStemField,
          'year': year,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rate = data['predicted_graduation_rate'];
        setState(() {
          _resultText = '🎓 Predicted Female Graduation Rate:\n${rate}%';
          _hasError = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _resultText = '❌ Error: ${error['detail'] ?? 'Something went wrong.'}';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _resultText = '❌ Could not connect to the server. Please try again.';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _enrollmentController.dispose();
    _genderGapController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        title: const Text(
          'Women in STEM Predictor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'Predict Female Graduation Rate in STEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Empowering women in tech across Africa',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Prediction Values',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E24AA),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Female Enrollment
                  _buildTextField(
                    controller: _enrollmentController,
                    label: 'Female Enrollment (%)',
                    hint: 'e.g. 45.0',
                    icon: Icons.school,
                    keyboardType: TextInputType.number,
                    helper: 'Range: 0 - 100',
                  ),

                  const SizedBox(height: 14),

                  // Gender Gap Index
                  _buildTextField(
                    controller: _genderGapController,
                    label: 'Gender Gap Index',
                    hint: 'e.g. 0.72',
                    icon: Icons.balance,
                    keyboardType: TextInputType.number,
                    helper: 'Range: 0.0 - 1.0',
                  ),

                  const SizedBox(height: 14),

                  // Year
                  _buildTextField(
                    controller: _yearController,
                    label: 'Year',
                    hint: 'e.g. 2022',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    helper: 'Range: 2000 - 2030',
                  ),

                  const SizedBox(height: 14),

                  // STEM Field Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STEM Field',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCE93D8)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFFCF4FF),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStemField,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF8E24AA)),
                            items: _stemFields.map((field) {
                              return DropdownMenuItem(
                                value: field,
                                child: Row(
                                  children: [
                                    const Icon(Icons.science,
                                        size: 18, color: Color(0xFF8E24AA)),
                                    const SizedBox(width: 8),
                                    Text(field),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedStemField = value!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Predict Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Predict',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Result display
            if (_resultText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hasError
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasError
                        ? const Color(0xFFEF9A9A)
                        : const Color(0xFFCE93D8),
                  ),
                ),
                child: Text(
                  _resultText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _hasError ? 14 : 22,
                    fontWeight: FontWeight.bold,
                    color: _hasError
                        ? const Color(0xFFC62828)
                        : const Color(0xFF6A1B9A),
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            prefixIcon: Icon(icon, color: const Color(0xFF8E24AA), size: 20),
            filled: true,
            fillColor: const Color(0xFFFCF4FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCE93D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCE93D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF8E24AA), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
} 
