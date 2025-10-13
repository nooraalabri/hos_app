class Validators {
  static final RegExp _passRe = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$'
  );

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!_passRe.hasMatch(v)) {
      return 'Min 8 chars incl. upper, lower, number & special';
    }
    return null;
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please re-enter password';
    if (v != original) return 'Passwords do not match';
    return null;
  }
}
