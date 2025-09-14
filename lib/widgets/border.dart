import 'package:flutter/material.dart';

OutlineInputBorder _appOutlineBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFA7A7A7)),
  );
}

InputDecoration appInputDecoration({
  required String label,
  String? hint,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: _appOutlineBorder(),
    enabledBorder: _appOutlineBorder(),
    focusedBorder: _appOutlineBorder(),
    disabledBorder: _appOutlineBorder(),
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

class AppTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;

  const AppTextFormField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: appInputDecoration(label: label, hint: hint),
      validator: validator,
    );
  }
}