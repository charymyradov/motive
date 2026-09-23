import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum HomeTab { feed, cards, analyze, me }

enum SpotlightKind { unlock, detail }

/// A card shown full-screen above the tabs.
class Spotlight extends Equatable {
  const Spotlight(this.kind, this.cardId);
  final SpotlightKind kind;
  final String cardId;
  @override
  List<Object?> get props => [kind, cardId];
}

class HomeState extends Equatable {
  const HomeState({this.tab = HomeTab.feed, this.spotlight});

  final HomeTab tab;
  final Spotlight? spotlight;

  @override
  List<Object?> get props => [tab, spotlight];
}

/// Navigation of the main shell: selected tab and the card overlay.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void selectTab(HomeTab tab) => emit(HomeState(tab: tab));
  void showUnlock(String cardId) => emit(HomeState(tab: state.tab, spotlight: Spotlight(SpotlightKind.unlock, cardId)));
  void showDetail(String cardId) => emit(HomeState(tab: state.tab, spotlight: Spotlight(SpotlightKind.detail, cardId)));
  void closeSpotlight() => emit(HomeState(tab: state.tab));
}
