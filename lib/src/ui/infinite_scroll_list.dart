import 'package:flutter/material.dart';

import '../../dropsource_utils.dart';
import 'grouped_list_view.dart';

class InfiniteScrollList<T extends Identifiable> extends StatefulWidget {
  InfiniteScrollList({
    this.listKey,
    this.model,
    this.itemBuilder,
    this.separatorBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.scrollController,
    this.refreshColor,
    this.refreshBackgroundColor,
    this.brightness,
    this.overlays,
    this.padding,
    this.extraItemCount,
  }) : key = listKey != null ? PageStorageKey(listKey) : null;
  final ScrollController scrollController;
  final ListNetworkingModel<T> model;
  final Color refreshColor, refreshBackgroundColor;
  final String listKey;
  final RefreshCallback onRefresh, onLoadMore;
  final IndexedWidgetBuilder itemBuilder, separatorBuilder;
  final WidgetBuilder errorBuilder, emptyBuilder;
  final Brightness brightness;
  final List<Widget> overlays;
  final EdgeInsetsGeometry padding;
  final int extraItemCount;

  final PageStorageKey key;

  int get extraItemsNeeded {
    int _count = extraItemCount ?? 0;
    if (model.hasData && loadMoreEnabled) {
      _count++;
    } else if ((model.hasError && errorBuilder != null) ||
        (!model.hasData && emptyBuilder != null)) {
      _count++;
    }

    return _count;
  }

  bool get loadMoreEnabled =>
      (model.shouldLoadMore != null) &&
      onLoadMore != null &&
      (model.canLoadMore != null);

  int get calculatedItemCount => model.itemCount + extraItemsNeeded;

  bool get hasDataOrIsLoading => model.hasData || (model.isInProgress ?? false);

  RefreshIndicator refreshableList() => RefreshIndicator(
        backgroundColor: refreshBackgroundColor,
        color: refreshColor,
        onRefresh: onRefresh,
        child: listView(scrollController),
      );

  ScrollPhysics get scrollPhysics => const AlwaysScrollableScrollPhysics();

  Widget listView(ScrollController controller) {
    if (separatorBuilder == null) {
      return ListView.builder(
        key: key,
        controller: controller,
        physics: scrollPhysics,
        itemCount: calculatedItemCount,
        padding: padding,
        itemBuilder:
            hasDataOrIsLoading ? hasDataOrLoadingBuilder : emptyOrErrorBuilder,
      );
    } else {
      return ListView.separated(
        key: key,
        controller: controller,
        physics: scrollPhysics,
        itemCount: calculatedItemCount,
        padding: padding,
        separatorBuilder: separatorBuilder,
        itemBuilder:
            hasDataOrIsLoading ? hasDataOrLoadingBuilder : emptyOrErrorBuilder,
      );
    }
  }

  Widget hasDataOrLoadingBuilder(BuildContext context, int position) {
    if (loadMoreEnabled && position == (calculatedItemCount - 1)) {
      // Scroll more loader
      if (model.canLoadMore) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: PlatformLoader(
            centered: true,
            brightness: brightness,
          ),
        );
      } else {
        return SizedBox();
      }
    } else if (!model.hasData) {
      return SizedBox();
    } else {
      return itemBuilder(context, position);
    }
  }

  Widget emptyOrErrorBuilder(BuildContext context, int position) {
    if (position == calculatedItemCount - 1) {
      // Scroll more loader
      if (model.hasError) {
        return errorBuilder(context);
      } else {
        return emptyBuilder(context);
      }
    } else {
      return itemBuilder(context, position);
    }
  }

  @override
  _InfinteScrollListState createState() => _InfinteScrollListState();
}

class _InfinteScrollListState extends State<InfiniteScrollList> {
  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null && widget.loadMoreEnabled)
      widget.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (widget.scrollController.position.pixels ==
            widget.scrollController.position.maxScrollExtent &&
        widget.model.shouldLoadMore) {
      print('LOAD MORE');
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWrapper(
      loading: widget.model?.isInProgress,
      loaderBrightness: widget.brightness,
      children: <Widget>[
        if (widget.onRefresh != null)
          widget.refreshableList()
        else
          widget.listView(widget.scrollController),
        ...(widget.overlays ?? []),
      ],
    );
  }
}

class GroupedInfiniteScrollList<T extends Identifiable, E>
    extends InfiniteScrollList<T> {
  GroupedInfiniteScrollList({
    this.groupBy,
    this.groupSeparatorBuilder,
    this.useStickHeader = false,
    ScrollController scrollController,
    ListNetworkingModel<T> model,
    Color refreshColor,
    Color refreshBackgroundColor,
    String listKey,
    RefreshCallback onRefresh,
    RefreshCallback onLoadMore,
    IndexedWidgetBuilder itemBuilder,
    IndexedWidgetBuilder separatorBuilder,
    WidgetBuilder errorBuilder,
    WidgetBuilder emptyBuilder,
    Brightness brightness,
    List<Widget> overlays,
    EdgeInsetsGeometry padding,
    int extraItemCount,
    this.order,
  }) : super(
          scrollController: scrollController,
          model: model,
          refreshColor: refreshColor,
          refreshBackgroundColor: refreshBackgroundColor,
          listKey: listKey,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          itemBuilder: itemBuilder,
          separatorBuilder: separatorBuilder,
          emptyBuilder: emptyBuilder,
          errorBuilder: errorBuilder,
          brightness: brightness,
          overlays: overlays,
          padding: padding,
          extraItemCount: extraItemCount,
        );

  final E Function(T element) groupBy;
  final Widget Function(BuildContext contex, E value) groupSeparatorBuilder;
  final bool useStickHeader;
  final GroupedListOrder order;
  @override
  Widget listView(ScrollController controller) {
    return GroupedListView<T, E>(
      key: super.key,
      elements: model.listData,
      groupBy: groupBy,
      sort: false,
      groupSeparatorBuilder: groupSeparatorBuilder,
      itemBuilder: (ctx, _, i) => hasDataOrIsLoading
          ? super.hasDataOrLoadingBuilder(ctx, i)
          : super.emptyOrErrorBuilder(ctx, i),
      physics: scrollPhysics,
      padding: padding,
      controller: controller,
      useStickyGroupSeparators: useStickHeader,
      order: order,
    );
  }
}
