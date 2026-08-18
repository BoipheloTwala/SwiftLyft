import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enablePullDown;
  final bool enablePullUp;
  final Future<void> Function()? onLoadMore;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!enablePullDown && !enablePullUp) {
      return child;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: SwiftLyftTheme.primaryBlue,
      backgroundColor: SwiftLyftTheme.pureWhite,
      strokeWidth: 3,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (enablePullUp && 
              onLoadMore != null &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            onLoadMore!();
          }
          return false;
        },
        child: child,
      ),
    );
  }
}

class InfiniteScrollList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final EdgeInsets? padding;

  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.emptyWidget,
    this.padding,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const Center(
        child: Text('No items found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
} 