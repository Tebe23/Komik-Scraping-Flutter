import 'package:flutter/material.dart';

enum ErrorType {
  network,
  server,
  parse,
  download,
  storage,
  unknown
}

class ErrorHandler {
  static String getErrorMessage(ErrorType type, [String? details]) {
    switch (type) {
      case ErrorType.network:
        return 'Network error. Please check your connection.';
      case ErrorType.server:
        return 'Server error. Please try again later.';
      case ErrorType.parse:
        return 'Error processing data. Please try again.';
      case ErrorType.download:
        return 'Download failed. Please try again.';
      case ErrorType.storage:
        return 'Storage error. Please check available space.';
      case ErrorType.unknown:
        return 'An unexpected error occurred.';
    }
  }

  static void showError(BuildContext context, ErrorType type, [String? details]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(type, details)),
        action: details != null
            ? SnackBarAction(
                label: 'Details',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error Details'),
                      content: Text(details),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  static Widget errorWidget(ErrorType type, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(type),
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            getErrorMessage(type),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.signal_wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.parse:
        return Icons.error_outline;
      case ErrorType.download:
        return Icons.file_download_off;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.error;
    }
  }
}