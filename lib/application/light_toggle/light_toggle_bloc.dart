import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cybear_jinni/domain/devices/abstract_device/device_entity_abstract.dart';
import 'package:cybear_jinni/domain/devices/device/devices_failures.dart';
import 'package:cybear_jinni/domain/devices/device/i_device_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'light_toggle_bloc.freezed.dart';
part 'light_toggle_event.dart';
part 'light_toggle_state.dart';

@injectable
class LightToggleBloc extends Bloc<LightToggleEvent, LightToggleState> {
  LightToggleBloc(this._deviceRepository) : super(LightToggleState.initial());

  final IDeviceRepository _deviceRepository;

  int sendNewColorEachMiliseconds = 200;
  Timer? timeFromLastColorChange;
  HSVColor? lastColoredPicked;

  @override
  Stream<LightToggleState> mapEventToState(
    LightToggleEvent event,
  ) async* {
    yield* event.map(
      create: (e) async* {
        final actionResult = await _deviceRepository.create(event.deviceEntity);
      },
      changeAction: (e) async* {
        Either<DevicesFailure, Unit> actionResult;

        if (e.changeToState) {
          actionResult = await _deviceRepository.turnOnDevices(
            devicesId: [e.deviceEntity.uniqueId.getOrCrash()!],
          );
        } else {
          actionResult = await _deviceRepository.turnOffDevices(
            devicesId: [e.deviceEntity.uniqueId.getOrCrash()!],
          );
        }
      },
      changeColor: (_ChangeColor e) async* {
        lastColoredPicked = e.newColor;
        timeFromLastColorChange ??=
            Timer(Duration(milliseconds: sendNewColorEachMiliseconds), () {
          changeColorOncePerTimer(e);
          timeFromLastColorChange = null;
        });
        yield state.copyWith(hsvColor: lastColoredPicked!);
      },
      changeBrightness: (_ChangeBrightness value) async* {
        yield state.copyWith(brightness: value.brightness);
      },
    );
  }

  /// This function will make sure that the app sends color once each x seconds.
  /// Moving the hand on the color slider sends tons of requests with
  /// different colors which is not efficient and some device can't even handle
  /// so many requests.
  Future<void> changeColorOncePerTimer(_ChangeColor e) async {
    await _deviceRepository.changeColorDevices(
      devicesId: [e.deviceEntity.uniqueId.getOrCrash()!],
      colorToChange: lastColoredPicked!,
    );
  }
}
