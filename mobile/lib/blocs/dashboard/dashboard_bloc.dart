import 'dart:async';

import 'package:app/models/models.dart';
import 'package:app/utils/extensions.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/hive_service.dart';
import '../../utils/dashboard.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc()
      : super(const DashboardState(
          greetings: '',
          incompleteKya: [],
          airQualityReadings: [],
          loading: false,
        )) {
    on<UpdateGreetings>(_onUpdateGreetings);
    on<InitializeDashboard>(_onInitializeDashboard);
  }

  Future<void> _onUpdateGreetings(
    UpdateGreetings event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading(
      greetings: state.greetings,
      incompleteKya: state.incompleteKya,
      airQualityReadings: state.airQualityReadings,
      loading: true,
    ));
    final greetings = await DateTime.now().getGreetings();

    return emit(state.copyWith(greetings: greetings));
  }

  Future<List<AirQualityReading>> _getAirQualityReadings() async {
    final airQualityCards = <AirQualityReading>[];

    final preferences = await SharedPreferences.getInstance();
    final region = getNextDashboardRegion(preferences);
    final regionAirQualityReadings =
        Hive.box<AirQualityReading>(HiveBox.airQualityReadings)
            .values
            .where((element) => element.region == region)
            .toList()
          ..shuffle();

    for (final regionAirQualityReading in regionAirQualityReadings.take(8)) {
      airQualityCards.add(
        AirQualityReading.duplicate(regionAirQualityReading),
      );
    }

    return airQualityCards;
  }

  Future<void> _onInitializeDashboard(
    InitializeDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading(
      greetings: state.greetings,
      incompleteKya: state.incompleteKya,
      airQualityReadings: state.airQualityReadings,
      loading: true,
    ));

    final greetings = await DateTime.now().getGreetings();
    final incompleteKya = await Kya.getIncompleteKya();
    final airQualityReadings = await _getAirQualityReadings();

    return emit(DashboardState(
      greetings: greetings,
      incompleteKya: incompleteKya,
      airQualityReadings: airQualityReadings,
      loading: false,
    ));
  }
}
