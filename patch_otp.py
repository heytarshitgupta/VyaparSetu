import re

filepath = r'f:\Utthaan\lib\buyer_section\auth\buyer_otp_verification_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace didChangeDependencies
did_change_replacement = """
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _email = args?['email']?.toString() ?? '';
    _mode = args?['mode']?.toString() ?? 'signIn';
  }
"""
content = re.sub(
    r'@override\s*void didChangeDependencies\(\) \{.*?\}',
    did_change_replacement.strip(),
    content,
    flags=re.DOTALL
)

# Add check to _verifyOtp
verify_replacement = """
  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6 || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Email is missing. Please go back and try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
"""
content = content.replace(
    """  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6 || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {""",
    verify_replacement.strip()
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
