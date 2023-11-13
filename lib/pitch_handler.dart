library pitchupdart;

import 'dart:math';

import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_result.dart';
import 'package:pitchupdart/tuning_status.dart';

class PitchHandler {
  final InstrumentType _instrumentType;
  final String? selectedNote;
  dynamic _minimumPitch;
  dynamic _maximumPitch;
  dynamic _noteStrings;

  static const Map<String, double> _noteFrequencies = {
    'E4': 329.63,
    'B3': 246.94,
    'G3': 196.00,
    'D3': 146.83,
    'A2': 110.00,
    'E2': 82.41,
  };

  PitchHandler(this._instrumentType, {this.selectedNote}) {
    switch (_instrumentType) {
      case InstrumentType.guitar:
        _minimumPitch = 80.0;
        _maximumPitch = 1050.0;
        _noteStrings = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        break;
    }
  }

  PitchResult handlePitch(double pitch) {
    print('Handling pitch: $pitch');
    if (_isPitchInRange(pitch)) {
      var expectedFrequency = 0.0;
      if (selectedNote != null && _noteFrequencies.containsKey(selectedNote)) {
        print('Setting $selectedNote : ${_noteFrequencies[selectedNote]}');
        expectedFrequency = _noteFrequencies[selectedNote] as double;
      } else {
        print('Auto Detecting note');
        expectedFrequency = _frequencyFromNoteNumber(_midiFromPitch(pitch));
      }
      final noteLiteral = _noteFromPitch(pitch);
      print('Expected Frequency: $expectedFrequency');
      final diff = _diffFromTargetedNote(pitch);
      final tuningStatus = _getTuningStatus(diff);
      final diffCents = _diffInCents(expectedFrequency, expectedFrequency - diff);

      return PitchResult(noteLiteral, tuningStatus, expectedFrequency, diff, diffCents);
    }

    return PitchResult("", TuningStatus.undefined, 0.00, 0.00, 0.00);
  }

  bool _isPitchInRange(double pitch) {
    return pitch > _minimumPitch && pitch < _maximumPitch;
  }

  String _noteFromPitch(double frequency) {
    final noteNum = 12.0 * (log((frequency / 440.0)) / log(2.0));
    return _noteStrings[((noteNum.roundToDouble() + 69.0).toInt() % 12.0).toInt()];
  }

  double _diffFromTargetedNote(double pitch) {
    final targetPitch = _frequencyFromNoteNumber(_midiFromPitch(pitch));
    return targetPitch - pitch;
  }

  double _diffInCents(double expectedFrequency, double frequency) {
    return 1200.0 * log(expectedFrequency / frequency);
  }

  TuningStatus _getTuningStatus(double diff) {
    if (diff >= -0.3 && diff <= 0.3) {
      return TuningStatus.tuned;
    } else if (diff >= -1.0 && diff <= 0.0) {
      return TuningStatus.tooHigh;
    } else if (diff > 0.0 && diff <= 1.0) {
      return TuningStatus.tooLow;
    } else if (diff >= double.negativeInfinity && diff <= -1.0) {
      return TuningStatus.wayTooHigh;
    } else {
      return TuningStatus.wayTooLow;
    }
  }

  int _midiFromPitch(double frequency) {
    final noteNum = 12.0 * (log((frequency / 440.0)) / log(2.0));
    return (noteNum.roundToDouble() + 69.0).toInt();
  }

  double _frequencyFromNoteNumber(int note) {
    final exp = (note - 69.0).toDouble() / 12.0;
    return (440.0 * pow(2.0, exp)).toDouble();
  }
}
