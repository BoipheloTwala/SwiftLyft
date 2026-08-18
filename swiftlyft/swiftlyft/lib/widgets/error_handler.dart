import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/error_tracker.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? errorType,
    Map<String, dynamic>? errorContext,
    StackTrace? stackTrace,
  }) {
    // Track error with context
    ErrorTracker.logError(
      errorType: errorType ?? 'UIError',
      message: message,
      stackTrace: stackTrace,
      context: errorContext,
      screenName: ModalRoute.of(context)?.settings.name,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: const TextStyle(color: SwiftLyftTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: onRetry != null ? 'Retry' : 'Dismiss',
          textColor: SwiftLyftTheme.pureWhite,
          onPressed: onRetry ?? onDismiss ?? () {},
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message, {
    String? title,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: const TextStyle(color: SwiftLyftTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.successGreen,
        duration: const Duration(seconds: 3),
        action: onAction != null ? SnackBarAction(
          label: 'Action',
          textColor: SwiftLyftTheme.pureWhite,
          onPressed: onAction,
        ) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {
    String? title,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: const TextStyle(color: SwiftLyftTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.warmOrange,
        duration: const Duration(seconds: 4),
        action: onAction != null ? SnackBarAction(
          label: 'Action',
          textColor: SwiftLyftTheme.pureWhite,
          onPressed: onAction,
        ) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {
    String? title,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: const TextStyle(color: SwiftLyftTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: SwiftLyftTheme.primaryBlue,
        duration: const Duration(seconds: 3),
        action: onAction != null ? SnackBarAction(
          label: 'Action',
          textColor: SwiftLyftTheme.pureWhite,
          onPressed: onAction,
        ) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SwiftLyftTheme.primaryBlue,
                  foregroundColor: SwiftLyftTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (onDismiss != null)
              TextButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
          ],
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(SwiftLyftTheme.primaryBlue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: SwiftLyftTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SwiftLyftTheme.deepCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Set up error handling - only catch errors when not building
    FlutterError.onError = (FlutterErrorDetails details) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stackTrace = details.stack;
          });
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    // Check if we have MaterialApp context
    final hasMaterialApp = context.findAncestorWidgetOfExactType<MaterialApp>() != null;

    if (hasMaterialApp) {
      // Use Scaffold if we have MaterialApp context
      return Scaffold(
        backgroundColor: SwiftLyftTheme.lightGray,
        body: _buildErrorContent(),
      );
    } else {
      // Use basic widgets if no MaterialApp context (root level error)
      // Provide Directionality since we don't have MaterialApp
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: SwiftLyftTheme.lightGray,
          child: _buildErrorContent(),
        ),
      );
    }
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.deepCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'We encountered an unexpected error. Please try again.',
              style: TextStyle(
                fontSize: 16,
                color: SwiftLyftTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SwiftLyftTheme.primaryBlue,
                    foregroundColor: SwiftLyftTheme.pureWhite,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // For root level errors, just reset the error since navigation won't work
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SwiftLyftTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 