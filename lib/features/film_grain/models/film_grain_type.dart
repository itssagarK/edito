import 'package:flutter/material.dart';

/// Supported photographic film stocks and procedural grain textures.
enum FilmGrainType {
  celluloid35mm,
  celluloid16mm,
  super8,
  silverHalide,
  analogTape,
  digitalIso;

  String get label {
    switch (this) {
      case FilmGrainType.celluloid35mm:
        return '35mm Film';
      case FilmGrainType.celluloid16mm:
        return '16mm Indie';
      case FilmGrainType.super8:
        return 'Super 8mm';
      case FilmGrainType.silverHalide:
        return 'Silver Halide';
      case FilmGrainType.analogTape:
        return 'Analog Tape';
      case FilmGrainType.digitalIso:
        return 'Digital ISO';
    }
  }

  String get subtitle {
    switch (this) {
      case FilmGrainType.celluloid35mm:
        return 'Kodak Vision3 500T organic motion picture grain';
      case FilmGrainType.celluloid16mm:
        return 'Coarser, gritty indie cinema emulsion';
      case FilmGrainType.super8:
        return 'Chunky vintage home-movie celluloid texture';
      case FilmGrainType.silverHalide:
        return 'Classic B&W archival monochrome silver crystals';
      case FilmGrainType.analogTape:
        return '90s VHS magnetic tape hiss and scanline drift';
      case FilmGrainType.digitalIso:
        return 'High-gain camera sensor noise profile';
    }
  }

  IconData get icon {
    switch (this) {
      case FilmGrainType.celluloid35mm:
        return Icons.movie_filter;
      case FilmGrainType.celluloid16mm:
        return Icons.camera_roll;
      case FilmGrainType.super8:
        return Icons.videocam;
      case FilmGrainType.silverHalide:
        return Icons.filter_b_and_w;
      case FilmGrainType.analogTape:
        return Icons.cassette;
      case FilmGrainType.digitalIso:
        return Icons.grain;
    }
  }
}
