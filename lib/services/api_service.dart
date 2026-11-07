import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


enum AppFailureType { network, server, parse, unknown }

/// A user-presentable application error.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.type = AppFailureType.unknown,
    this.cause,
  });

  final String message;
  final AppFailureType type;
  final Object? cause;

  bool get isNetworkFailure => type == AppFailureType.network;

  @override
  String toString() => 'AppException($type): $message';
}

/// Raw payloads returned by the four iptv-org endpoints.
class RawCatalogData {
  const RawCatalogData({
    required this.channels,
    required this.streams,
    required this.logos,
    required this.feeds,
  });

  final List<dynamic> channels;
  final List<dynamic> streams;
  final List<dynamic> logos;
  final List<dynamic> feeds;
}

/// Dio wrapper for the public iptv-org API.
class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
              headers: const <String, String>{
                'Accept': 'application/json',
                'User-Agent': 'SportzfyClone/1.0 (Flutter learning project)',
              },
            ),
          );

  final Dio _dio;

  static const String channelsUrl =
      'https://iptv-org.github.io/api/channels.json';
  static const String streamsUrl =
      'https://iptv-org.github.io/api/streams.json';
  static const String feedsUrl = 'https://iptv-org.github.io/api/feeds.json';
  static const String logosUrl = 'https://iptv-org.github.io/api/logos.json';

  Future<List<dynamic>> fetchChannels() => _getList(channelsUrl);
  Future<List<dynamic>> fetchStreams() => _getList(streamsUrl);
  Future<List<dynamic>> fetchLogos() => _getList(logosUrl);
  Future<List<dynamic>> fetchFeeds() => _getList(feedsUrl);

  /// Downloads all four data sets concurrently with individual error handling.
  /// If one endpoint fails, the others can still succeed.
  Future<RawCatalogData> fetchCatalog() async {
    final channelsFuture = fetchChannels().catchError((_) => <dynamic>[]);
    final streamsFuture = fetchStreams().catchError((_) => <dynamic>[]);
    final logosFuture = fetchLogos().catchError((_) => <dynamic>[]);
    final feedsFuture = fetchFeeds().catchError((_) => <dynamic>[]);

    final results = await Future.wait<List<dynamic>>(<Future<List<dynamic>>>[
      channelsFuture,
      streamsFuture,
      logosFuture,
      feedsFuture,
    ]);

    // If critical data is missing, throw so the caller can use cache.
    if (results[0].isEmpty && results[1].isEmpty) {
      throw const AppException(
        'No internet connection',
        type: AppFailureType.network,
      );
    }

    return RawCatalogData(
      channels: results[0],
      streams: results[1],
      logos: results[2],
      feeds: results[3],
    );
  }

  Future<List<dynamic>> _getList(String url) async {
    try {
      final response = await _dio.get<dynamic>(url);
      final data = response.data;

      if (data is List<dynamic>) return data;
      if (data is List) return List<dynamic>.from(data);

      // Some proxies return a JSON string instead of a decoded list.
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is List) return List<dynamic>.from(decoded);
      }

      throw const AppException(
        'Could not read data',
        type: AppFailureType.parse,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected API error: $error\n$stackTrace');
      throw AppException(
        'Could not read data',
        type: AppFailureType.parse,
        cause: error,
      );
    }
  }

  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return AppException(
          'No internet connection',
          type: AppFailureType.network,
          cause: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return AppException(
          statusCode == null
              ? 'Server error'
              : 'Server error (${statusCode.toString()})',
          type: AppFailureType.server,
          cause: error,
        );
      case DioExceptionType.cancel:
        return AppException(
          'Something went wrong',
          type: AppFailureType.unknown,
          cause: error,
        );
      case DioExceptionType.transformTimeout:
        return AppException(
          'Could not read data',
          type: AppFailureType.parse,
          cause: error,
        );
      case DioExceptionType.unknown:
        final description = error.error?.toString().toLowerCase() ?? '';
        final looksLikeNetworkError =
            description.contains('socket') ||
            description.contains('network') ||
            description.contains('connection') ||
            description.contains('xmlhttprequest');
        return AppException(
          looksLikeNetworkError
              ? 'No internet connection'
              : 'Something went wrong',
          type: looksLikeNetworkError
              ? AppFailureType.network
              : AppFailureType.unknown,
          cause: error,
        );
    }
  }
}
