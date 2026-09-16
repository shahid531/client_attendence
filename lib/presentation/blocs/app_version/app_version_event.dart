import 'package:equatable/equatable.dart';

abstract class AppVersionEvent extends Equatable {
  const AppVersionEvent();

  @override
  List<Object?> get props => [];
}

class CheckAppVersionEvent extends AppVersionEvent {
  const CheckAppVersionEvent();
}
