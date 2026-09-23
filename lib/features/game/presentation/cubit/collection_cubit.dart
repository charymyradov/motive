import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CollectionView { cards, paths }

class CollectionState extends Equatable {
  const CollectionState({this.view = CollectionView.cards, this.filter});

  final CollectionView view;

  /// Field id to filter the card grid by; null = all.
  final String? filter;

  @override
  List<Object?> get props => [view, filter];
}

/// Pure UI state of the Collection tab.
class CollectionCubit extends Cubit<CollectionState> {
  CollectionCubit() : super(const CollectionState());

  void showView(CollectionView view) => emit(CollectionState(view: view, filter: state.filter));
  void setFilter(String? fieldId) => emit(CollectionState(view: state.view, filter: fieldId));
}
