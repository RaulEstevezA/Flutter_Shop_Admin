import 'package:formz/formz.dart';

// Define input validation errors
enum ConfirmedPasswordError { empty, mismatch }

// Extend FormzInput and provide the input type and error type.
class ConfirmedPassword extends FormzInput<String, ConfirmedPasswordError> {

  // Contraseña original con la que se tiene que comparar
  final String password;

  // Call super.pure to represent an unmodified form input.
  const ConfirmedPassword.pure({ this.password = '' }) : super.pure('');

  // Call super.dirty to represent a modified form input.
  const ConfirmedPassword.dirty({ required this.password, String value = '' }) : super.dirty(value);


  String? get errorMessage {
    if ( isValid || isPure ) return null;

    if ( displayError == ConfirmedPasswordError.empty ) return 'El campo es requerido';
    if ( displayError == ConfirmedPasswordError.mismatch ) return 'Las contraseñas no coinciden';

    return null;
  }

  // Override validator to handle validating a given input value.
  @override
  ConfirmedPasswordError? validator(String value) {

    if ( value.isEmpty || value.trim().isEmpty ) return ConfirmedPasswordError.empty;
    if ( value != password ) return ConfirmedPasswordError.mismatch;

    return null;
  }
}
