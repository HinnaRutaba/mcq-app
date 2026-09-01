import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/core/network/api_exception.dart';

/// The four responses that matter, classified once.
///
/// Getting 401 and 403 the wrong way round produces "the app logs me out
/// when I tap things" — the exact bug the web application shipped and had to
/// have fixed. These tests are what stop it happening here.
void main() {
  DioException failure(int status, Map<String, dynamic> body) => DioException(
        requestOptions: RequestOptions(path: '/enforcement/cases/1/seal'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/enforcement/cases/1/seal'),
          statusCode: status,
          data: body,
        ),
        type: DioExceptionType.badResponse,
      );

  test('401 is the only status that ends the session', () {
    final error = ApiException.fromDio(
      failure(401, {'message': 'Unauthenticated.'}),
    );
    expect(error.kind, ApiFailureKind.unauthenticated);
    expect(error.isUnauthenticated, isTrue);
    expect(error.message, 'Unauthenticated.');
  });

  test('403 is the refusal of one action, and keeps the server sentence', () {
    final error = ApiException.fromDio(failure(403, {
      'message': 'You do not have permission to do that.',
      'code': 'forbidden',
    }));
    expect(error.kind, ApiFailureKind.forbidden);
    expect(error.isUnauthenticated, isFalse);
    expect(error.message, 'You do not have permission to do that.');
    expect(error.code, 'forbidden');
    expect(error.fromServer, isTrue);
  });

  test('409 is a domain refusal the screen has to show', () {
    final error = ApiException.fromDio(failure(409, {
      'message': 'The dues are not cleared, so this seal cannot be released.',
      'code': 'dues_outstanding',
    }));
    expect(error.isConflict, isTrue);
    // Shown verbatim — never replaced with "Something went wrong".
    expect(
      error.message,
      'The dues are not cleared, so this seal cannot be released.',
    );
  });

  test('422 binds its errors onto the form fields', () {
    final error = ApiException.fromDio(failure(422, {
      'message': 'The given data was invalid.',
      'errors': {
        'legal_provision': ['The provision of law is required.'],
        'offender_mobile_no': ['Enter a valid mobile number.'],
      },
    }));
    expect(error.isValidation, isTrue);
    expect(
      error.errorFor('legal_provision'),
      'The provision of law is required.',
    );
    expect(error.errorFor('fine_amount'), isNull);
  });

  test('a 5xx is reported, and is not a session problem', () {
    final error = ApiException.fromDio(failure(500, {'message': 'Server Error'}));
    expect(error.kind, ApiFailureKind.server);
    expect(error.isUnauthenticated, isFalse);
  });

  test('a lost connection is a network failure, not a refusal', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/reporting/dashboard'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(error.isNetwork, isTrue);
    expect(error.fromServer, isFalse);
    expect(error.message, isNotEmpty);
  });
}
