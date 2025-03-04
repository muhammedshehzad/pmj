import 'package:flutter/material.dart';

Widget textfieldbutton({
   required BuildContext context,
  required IconData suffixIcon,
  required Color iconColor,
  required String hintText,
  required String labelText,
  required TextEditingController textEditingController,
  required TextInputType keyboardinputtype,
  required String? Function(String?)? validatorr,
  required  void Function(String?)? onSavedfunction,
}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.9,
    child: TextFormField(
      onSaved: onSavedfunction,
      validator: validatorr,
      keyboardType: keyboardinputtype,
      controller: textEditingController,
      decoration: InputDecoration(
        suffixIcon: Icon(
          suffixIcon,
          color: iconColor,
          size: 24,
        ),
        hintText: hintText,
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black54,),
        focusColor: Color(0xff1BA3A1),
        hoverColor: Color(0xff1BA3A1),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xff1BA3A1), width: 2.0),  // Border color when focused
          borderRadius: BorderRadius.circular(8.0),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),

    ),
  );
}
