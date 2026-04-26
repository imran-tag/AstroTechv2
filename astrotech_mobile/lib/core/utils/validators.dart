class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    return null;
  }

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Ce champ']) {
    if (value == null || value.length < min) {
      return '$fieldName doit contenir au moins $min caractères';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Ce champ']) {
    if (value != null && value.length > max) {
      return '$fieldName ne doit pas dépasser $max caractères';
    }
    return null;
  }
}
