import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CollectionView { cards, paths }

/// How the card grid is ordered.
enum CollectionSort {
  /// Card number, i.e. the order they were released.
  number,

  /// Rarest first.
  rarity,

  /// Most recently collected first (uncollected last).
  recent,

  /// Field, then number — grouped by arena.
  arena,
}

class CollectionState extends Equatable {
  const CollectionState({
    this.view = CollectionView.cards,
    this.filter,
    this.sort = CollectionSort.number,
    this.query = '',
    this.searching = false,
  });

  final CollectionView view;

  /// Field id to filter the card grid by; null = all.
  final String? filter;

  final CollectionSort sort;

  /// Free-text search over the card question, force and arena name.
  final String query;

  /// Whether the search field is open.
  final bool searching;

  @override
  List<Object?> get props => [view, filter, sort, query, searching];

  CollectionState copyWith({
    CollectionView? view,
    CollectionSort? sort,
    String? query,
    bool? searching,
  }) =>
      CollectionState(
        view: view ?? this.view,
        filter: filter,
        sort: sort ?? this.sort,
        query: query ?? this.query,
        searching: searching ?? this.searching,
      );
}

/// Pure UI state of the Collection tab.
class CollectionCubit extends Cubit<CollectionState> {
  CollectionCubit() : super(const CollectionState());

  void showView(CollectionView view) =>
      emit(state.copyWith(view: view, searching: view == CollectionView.cards ? state.searching : false));

  void setFilter(String? fieldId) => emit(CollectionState(
        view: state.view,
        filter: fieldId,
        sort: state.sort,
        query: state.query,
        searching: state.searching,
      ));

  void setSort(CollectionSort sort) => emit(state.copyWith(sort: sort));

  void setQuery(String query) => emit(state.copyWith(query: query));

  void toggleSearch() => emit(state.copyWith(
        searching: !state.searching,
        query: state.searching ? '' : state.query,
      ));
}
