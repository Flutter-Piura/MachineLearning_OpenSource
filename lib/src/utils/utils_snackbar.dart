// ignore_for_file: unnecessary_null_comparison, deprecated_member_use

import 'package:flutter/material.dart';

void showSnackbar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      )));
}
