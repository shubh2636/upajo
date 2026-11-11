import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackendNotConfiguredApp extends StatelessWidget {
  final String reason;

  const BackendNotConfiguredApp({
    super.key,
    required this.reason,
  });

  static const String recommendedRunCommand =
      'flutter run --flavor dev \\\n'
      '  --dart-define=SUPABASE_URL=https://sskbabrsrbgjemsofiam.supabase.co \\\n'
      '  --dart-define=SUPABASE_ANON_KEY=sb_publishable_fGh_wsAUJv-wBPzastWBNQ_xu-ji3vY \\\n'
      '  --dart-define=API_BASE_URL=http://10.0.2.2:8000';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Backend Not Configured - Upajo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC0392B),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF9F9),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE57373), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 44,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Backend Not Configured',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB71C1C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'बैकएंड कॉन्फ़िगर नहीं है',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'The application cannot connect to Supabase because the backend URL or anon key is empty or contains placeholder values (such as "your-project.supabase.co"). Signups and logins are blocked until properly configured.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF424242),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Required Run Command:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF263238),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SelectableText(
                            recommendedRunCommand,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFFECEFF1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  const ClipboardData(text: recommendedRunCommand),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Run command copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF81D4FA),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Command', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

