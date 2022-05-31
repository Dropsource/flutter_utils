import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ds_ui.dart';

final ScrollPhysics alwaysBouncingScrollPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

class ScrollableAppBar extends SliverAppBar {
  ScrollableAppBar({
    Widget? title,
    bool floating = true,
    bool snap = true,
    bool stretch = false,
    double? appBarElevation,
    Color? backgroundColor,
    AsyncCallback? onStretchTrigger,
    double? expandedHeight,
    double? collapsedHeight,
    bool automaticallyImplyLeading = false,
  }) : super(
          automaticallyImplyLeading: automaticallyImplyLeading,
          floating: floating,
          snap: snap,
          stretch: stretch,
          backgroundColor: backgroundColor ?? Colors.transparent,
          leading: null,
          title: title,
          actions: [
            SizedBox()
          ], // Used to hide the Scaffold.endDrawer specified in home_page.dart
          elevation: appBarElevation,
          onStretchTrigger: onStretchTrigger,
          expandedHeight: expandedHeight,
          collapsedHeight: collapsedHeight,
        );
}

class ScrollableAppBarBehavior {
  const ScrollableAppBarBehavior({
    this.appBarExpandedHeight = 0,
    this.appBarCollapsedHeight,
    this.appBarColor,
    this.appBarHiddenUntilScroll = true,
    this.appBarBottom,
    this.appBarTitleSpacing = NavigationToolbar.kMiddleSpacing,
    this.scrollingAppBarTitle,
    this.backButton,
    this.scrollingHeader,
    this.appBarActions,
    this.pinned = false,
    this.stretch = false,
    this.snap = false,
    this.floating = false,
    this.appBarElevation,
    this.scrollingHeaderTitle,
    this.centerScrollingHeaderTitle,
    this.toolbarHeight = kToolbarHeight,
    this.flexibleSpaceCollapseMode = CollapseMode.pin,
    this.centerAppBarTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final Color? appBarColor;
  final Widget? scrollingAppBarTitle;
  final Widget? backButton;
  final Widget? scrollingHeader, scrollingHeaderTitle;
  final bool? centerScrollingHeaderTitle;
  final double? appBarExpandedHeight, appBarCollapsedHeight;
  final double appBarTitleSpacing;
  final PreferredSizeWidget? appBarBottom;
  final bool pinned, stretch, snap, floating;
  final double? appBarElevation;
  final List<Widget>? appBarActions;
  final CollapseMode flexibleSpaceCollapseMode;
  final double toolbarHeight;
  final bool appBarHiddenUntilScroll;
  final bool centerAppBarTitle, automaticallyImplyLeading;
}

class ScrollableLayout<T> extends StatefulWidget {
  ScrollableLayout({
    String? scrollKey,
    // AppBar
    this.appBarBehavior = const ScrollableAppBarBehavior(),
    // Loaders
    this.onRefresh,
    this.onLoadMore,

    // Builders
    this.itemBuilder,
    WidgetBuilder? loadMoreBuilder,
    // this.refreshControlBuilder,
    this.separatorBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.beforeSlivers,
    this.sliver,
    this.afterSlivers,
    this.overlays,
    this.bodyPadding,
    this.scrollController,

    // List
    this.shrinkWrap = false,
    this.shouldLoadMore,
    this.canLoadMore,
    this.isLoading,
    this.hasData,
    this.hasError,
    this.isLoadingMore,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.scrollPhysics =
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
  })  : key = scrollKey != null ? PageStorageKey(scrollKey) : null,
        loadMoreBuilder = loadMoreBuilder ??
            ((_) => SliverToBoxAdapter(child: PlatformLoader(centered: true)));

  final ScrollableAppBarBehavior? appBarBehavior;

  @override
  final PageStorageKey? key;
  final RefreshCallback? onRefresh, onLoadMore;
  final IndexedWidgetBuilder? itemBuilder, separatorBuilder;
  final WidgetBuilder? errorBuilder, emptyBuilder, loadMoreBuilder;

  final List<Widget>? beforeSlivers, afterSlivers, overlays;
  final Widget? sliver;
  final EdgeInsetsGeometry? bodyPadding;
  final bool? shrinkWrap;

  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  final bool Function()? shouldLoadMore,
      canLoadMore,
      isLoadingMore,
      isLoading,
      hasData,
      hasError;

  @override
  _ScrollableLayoutState createState() => _ScrollableLayoutState();
}

class _ScrollableLayoutState extends State<ScrollableLayout> {
  ScrollController? _controller;
  bool _isScrolled = false;
  bool get isLoading => widget.isLoading?.call() ?? false;
  bool get shouldLoadMore => widget.shouldLoadMore?.call() ?? false;
  bool get isLoadingMore => widget.isLoadingMore?.call() ?? false;
  bool get loadMoreEnabled =>
      (widget.shouldLoadMore != null) &&
      widget.onLoadMore != null &&
      (widget.canLoadMore != null);

  bool get hasData => widget.hasData?.call() ?? false;
  bool get hasError => widget.hasError?.call() ?? false;

  bool get hasDataOrIsLoading => hasData || isLoading;

  bool get _requiresScrollListener =>
      _hasFlexibleSpace && widget.appBarBehavior!.appBarHiddenUntilScroll;

  bool get _hasFlexibleSpace =>
      widget.appBarBehavior!.scrollingHeader != null &&
      widget.appBarBehavior!.appBarExpandedHeight != null;

  @override
  void initState() {
    super.initState();
    _controller = widget.scrollController ?? ScrollController();
    if (_requiresScrollListener) {
      _controller?.addListener(_listenToScrollChange(context));
    }

    if (loadMoreEnabled) {
      _controller?.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (widget.scrollController?.position.pixels ==
            widget.scrollController?.position.maxScrollExtent &&
        shouldLoadMore &&
        widget.onLoadMore != null) {
      print('LOAD MORE');
      widget.onLoadMore!();
    }
  }

  VoidCallback _listenToScrollChange(BuildContext context) => () {
        // TODO: need a better way of doing this so I don't have to lookup context over scroll
        try {
          final offset = MediaQuery.of(context).padding.top;
          if (_controller!.offset >=
                  (widget.appBarBehavior!.appBarExpandedHeight ?? 0) - offset &&
              mounted) {
            setState(() {
              _isScrolled = true;
            });
          } else if (_isScrolled && mounted) {
            setState(() {
              _isScrolled = false;
            });
          }
        } on TypeError catch (e) {
          print(e);
        }
      };

  @override
  Widget build(BuildContext context) {
    return LoadingWrapper(
      loading: isLoading,
      ignorePointerWhenLoading: false,
      children: [
        CustomScrollView(
          key: widget.key,
          controller: _controller,
          physics: widget.scrollPhysics,
          shrinkWrap: widget.shrinkWrap ?? false,
          keyboardDismissBehavior: widget.keyboardDismissBehavior,
          slivers: [
            if (widget.appBarBehavior != null)
              SliverAppBar(
                backgroundColor: widget.appBarBehavior!.appBarColor,
                toolbarHeight: widget.appBarBehavior!.toolbarHeight,
                automaticallyImplyLeading:
                    widget.appBarBehavior!.automaticallyImplyLeading,
                titleSpacing: widget.appBarBehavior!.appBarTitleSpacing,
                title: _requiresScrollListener
                    ? AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: _isScrolled ? 1.0 : 0.0,
                        curve: Curves.easeIn,
                        child: widget.appBarBehavior!.scrollingAppBarTitle,
                      )
                    : widget.appBarBehavior!.scrollingAppBarTitle,
                leading: widget.appBarBehavior!.backButton,
                actions: widget.appBarBehavior!.appBarActions,
                centerTitle: widget.appBarBehavior!.centerAppBarTitle,
                pinned: widget.appBarBehavior!.pinned,
                stretch: widget.appBarBehavior!.stretch,
                floating: widget.appBarBehavior!.floating,
                elevation: widget.appBarBehavior!.appBarElevation,
                snap: widget.appBarBehavior!.snap,
                expandedHeight: widget.appBarBehavior!.appBarExpandedHeight,
                collapsedHeight: widget.appBarBehavior!.appBarCollapsedHeight,
                primary: true,
                bottom: widget.appBarBehavior!.appBarBottom,
                flexibleSpace: _hasFlexibleSpace
                    ? FlexibleSpaceBar(
                        collapseMode:
                            widget.appBarBehavior!.flexibleSpaceCollapseMode,
                        background: widget.appBarBehavior!.scrollingHeader,
                        title: widget.appBarBehavior!.scrollingHeaderTitle,
                        centerTitle:
                            widget.appBarBehavior!.centerScrollingHeaderTitle,
                      )
                    : null,
              ),
            ...refreshBuilder,
            ...(widget.beforeSlivers ?? []),
            ...errorBuilder,
            ...emptyBuilder,
            ...hasDataOrLoadingBuilder,
            ...loadMoreBuilder,
            ...(widget.afterSlivers ?? []),
          ],
        ),
        ...(widget.overlays ?? [])
      ],
    );
  }

  List<Widget> get refreshBuilder => [
        if (widget.onRefresh != null)
          CupertinoSliverRefreshControl(
            onRefresh: widget.onRefresh,
            // builder: widget.refreshControlBuilder,
          ),
      ];

  List<Widget> get hasDataOrLoadingBuilder => [
        if (hasDataOrIsLoading && widget.sliver != null)
          SliverPadding(
            sliver: widget.sliver,
            padding: widget.bodyPadding ?? EdgeInsets.all(0),
          ),
      ];

  List<Widget> get loadMoreBuilder => [
        if (isLoadingMore && widget.loadMoreBuilder != null)
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: widget.loadMoreBuilder!(context),
          ),
      ];

  List<Widget> get emptyBuilder => [
        if (widget.emptyBuilder != null &&
            !hasError &&
            !hasData &&
            !isLoading &&
            widget.emptyBuilder != null)
          widget.emptyBuilder!(context),
      ];

  List<Widget> get errorBuilder => [
        if (widget.errorBuilder != null && hasError)
          widget.errorBuilder!(context),
      ];
}
