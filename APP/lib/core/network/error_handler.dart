import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Devuelve un mensaje legible en español a partir de cualquier error
/// (en particular [DioException]). Pensado para mostrar al usuario.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Comprueba tu conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Revisa tu conexión.';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada.';
      case DioExceptionType.badCertificate:
        return 'Certificado del servidor no válido.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final serverMessage = _extractServerMessage(error.response?.data);
        if (serverMessage != null && serverMessage.isNotEmpty) {
          return serverMessage;
        }
        if (status == 400) return 'Solicitud inválida.';
        if (status == 401) return 'Sesión expirada. Vuelve a iniciar sesión.';
        if (status == 403) return 'No tienes permisos para esta acción.';
        if (status == 404) return 'Recurso no encontrado.';
        if (status == 409) return 'Conflicto con el estado actual.';
        if (status >= 500) return 'Error del servidor. Inténtalo más tarde.';
        return 'Error HTTP $status.';
      case DioExceptionType.unknown:
        return 'Ha ocurrido un error inesperado.';
    }
  }
  // Exception('xxx') común en el repo
  final raw = error.toString();
  return raw.replaceFirst('Exception: ', '');
}

String? _extractServerMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    for (final key in const ['error', 'message', 'detail', 'title']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

/// Muestra el mensaje de error en un [SnackBar] sobre el [BuildContext] dado.
/// Es responsabilidad del llamador comprobar `context.mounted` previamente
/// si se invoca tras un await.
void showApiError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(content: Text(apiErrorMessage(error))),
  );
}
