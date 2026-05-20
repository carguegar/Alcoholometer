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
        final serverMessage = extractServerMessage(error.response?.data);
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

String? extractServerMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    if (data.containsKey('errors') && data['errors'] is Map) {
      final errorsMap = data['errors'] as Map;
      final messages = <String>[];
      for (final value in errorsMap.values) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else {
          messages.add(value.toString());
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }
    for (final key in const ['error', 'message', 'detail', 'title']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return _trimStackTrace(value);
    }
  }
  if (data is String && data.isNotEmpty) return _trimStackTrace(data);
  return null;
}

String _trimStackTrace(String message) {
  // If it looks like a C# exception stack trace
  if (message.contains('Exception:') || message.contains('\n   at ')) {
    final lines = message.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      final colonIndex = firstLine.indexOf(': ');
      if (colonIndex != -1) {
        return firstLine.substring(colonIndex + 2).trim();
      }
      return firstLine.trim();
    }
  }
  return message;
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

String extractErrorMessage(DioException e, String fallback) {
  if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
    return 'Tiempo de conexión agotado. Revisa tu internet.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Error de conexión. No se pudo conectar al servidor.';
  }
  final serverMessage = extractServerMessage(e.response?.data);
  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }
  return fallback;
}
