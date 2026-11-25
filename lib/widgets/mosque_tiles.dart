import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Inverts the tiles and turns the hues back round — the same matrix as
/// flutter_map's darkModeTileBuilder.
const _darkTileFilter = ColorFilter.matrix(<double>[
  0.574, -1.43, -0.144, 0, 255, //
  -0.426, -0.43, -0.144, 0, 255, //
  -0.426, -1.43, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

class MosqueTiles extends StatelessWidget {
  const MosqueTiles({super.key, this.onLoaded, this.onError});

  final VoidCallback? onLoaded;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: _tileUrl,
      maxNativeZoom: 19,
      userAgentPackageName: 'uz.mu1zi47.fiveglow',
      tileBuilder: onLoaded == null
          ? null
          : (context, child, tile) {
              if (tile.imageInfo != null && !tile.loadError) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onLoaded?.call(),
                );
              }
              return child;
            },
      errorTileCallback: onError == null
          ? null
          : (tile, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onError?.call(),
              );
            },
    );
    return Theme.of(context).brightness == Brightness.dark
        ? ColorFiltered(colorFilter: _darkTileFilter, child: tiles)
        : tiles;
  }
}
