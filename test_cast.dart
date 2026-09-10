void main() {
  final Map<String, String> original = {'email': 'test@test.com', 'mode': 'signIn'};
  final Object? args = original;
  
  final casted = args as Map<String, dynamic>?;
  print("Casted successfully? ${casted != null}");
  print("Email: ${casted?['email']}");
}
