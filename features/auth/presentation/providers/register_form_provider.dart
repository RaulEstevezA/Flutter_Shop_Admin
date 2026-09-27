import 'package:teslo_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:teslo_shop/features/shared/shared.dart';
import 'package:formz/formz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// 3 - StateNotifierProvider - consume afuera
final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier,RegisterFormState>((ref) {

  final registerUserCallback = ref.watch(authProvider.notifier).registerUser;


  return RegisterFormNotifier(
    registerUserCallback: registerUserCallback
  );
});

// 1 - State del provider
class RegisterFormState {

  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final FullName fullName;
  final Email email;
  final Password password;
  final ConfirmedPassword confirmedPassword;

  RegisterFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.fullName = const FullName.pure(),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.confirmedPassword = const ConfirmedPassword.pure(),
  });

  RegisterFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    FullName? fullName,
    Email? email,
    Password? password,
    ConfirmedPassword? confirmedPassword,
  }) => RegisterFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    password: password ?? this.password,
    confirmedPassword: confirmedPassword ?? this.confirmedPassword,
  );

  @override
  String toString() {
    return '''
  RegisterFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    fullName: $fullName
    email: $email
    password: $password
    confirmedPassword: $confirmedPassword
''';
  }
}

// 2 - Como implementamos un notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {

  final Future<void> Function(String, String, String) registerUserCallback;

  RegisterFormNotifier({
    required this.registerUserCallback,
  }): super( RegisterFormState() );

  onFullNameChanged( String value ) {
    final newFullName = FullName.dirty(value);
    state = state.copyWith(
      fullName: newFullName,
      isValid: Formz.validate([ newFullName, state.email, state.password, state.confirmedPassword ])
    );
  }

  onEmailChange( String value ) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([ state.fullName, newEmail, state.password, state.confirmedPassword ])
    );
  }

  onPasswordChanged( String value ) {
    final newPassword = Password.dirty(value);
    // Al cambiar la contraseña hay que volver a comprobar la confirmación
    final newConfirmedPassword = ConfirmedPassword.dirty(
      password: value,
      value: state.confirmedPassword.value
    );
    state = state.copyWith(
      password: newPassword,
      confirmedPassword: newConfirmedPassword,
      isValid: Formz.validate([ state.fullName, state.email, newPassword, newConfirmedPassword ])
    );
  }

  onConfirmedPasswordChanged( String value ) {
    final newConfirmedPassword = ConfirmedPassword.dirty(
      password: state.password.value,
      value: value
    );
    state = state.copyWith(
      confirmedPassword: newConfirmedPassword,
      isValid: Formz.validate([ state.fullName, state.email, state.password, newConfirmedPassword ])
    );
  }

  onFormSubmit() async {
    _touchEveryField();

    if ( !state.isValid ) return;

    state = state.copyWith( isPosting: true );

    await registerUserCallback( state.email.value, state.password.value, state.fullName.value.trim() );

    // El provider es autoDispose: si el registro fue bien, la pantalla ya no existe
    if ( !mounted ) return;
    state = state.copyWith( isPosting: false );
  }

  _touchEveryField() {

    final fullName = FullName.dirty(state.fullName.value);
    final email    = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final confirmedPassword = ConfirmedPassword.dirty(
      password: state.password.value,
      value: state.confirmedPassword.value
    );

    state = state.copyWith(
      isFormPosted: true,
      fullName: fullName,
      email: email,
      password: password,
      confirmedPassword: confirmedPassword,
      isValid: Formz.validate([ fullName, email, password, confirmedPassword ])
    );
  }
}
