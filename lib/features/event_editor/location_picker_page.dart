import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_anchor.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../security/security_dialogs.dart';

/// 只有此頁載入 OSM 圖資；不做地址查詢，也不傳事件名稱、作者或附件。
class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initial,
    this.privateCoordinates = false,
  });
  final LocationAnchor? initial;
  final bool privateCoordinates;
  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final controller = MapController();
  late final radius = TextEditingController(
    text: widget.initial?.radiusM?.toString() ?? '',
  );
  late LatLng? point = widget.initial == null
      ? null
      : LatLng(widget.initial!.latitude, widget.initial!.longitude);
  bool offline = false;
  int retry = 0;
  @override
  void dispose() {
    radius.dispose();
    controller.dispose();
    super.dispose();
  }

  double? get radiusValue => double.tryParse(radius.text);
  bool get validRadius =>
      radius.text.trim().isEmpty ||
      (radiusValue != null && radiusValue!.isFinite && radiusValue! > 0);
  LatLng _visible(LatLng value) =>
      LatLng(value.latitude.clamp(-85.0, 85.0), value.longitude);
  void _pick(LatLng value) => setState(
    () => point = LatLng(
      value.latitude.clamp(-90.0, 90.0),
      ((value.longitude + 180) % 360) - 180,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final security = ref.watch(securityProvider);
    if (widget.privateCoordinates && !security.canReadPrivate) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => authorizePrivate(context),
            child: Text(l.securityPrivateUnlock),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.locationMapPick)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: security.background
                  ? Center(child: Text(l.locationOffline))
                  : FlutterMap(
                      mapController: controller,
                      options: MapOptions(
                        initialCenter: _visible(point ?? const LatLng(0, 0)),
                        initialZoom: point == null ? 2 : 15,
                        onTap: (_, value) => _pick(value),
                      ),
                      children: [
                        TileLayer(
                          key: ValueKey(retry),
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'io.github.bruce_yang_422.life_chronicle',
                          errorTileCallback: (_, error, stack) {
                            if (!offline) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => offline = true);
                              });
                            }
                          },
                        ),
                        if (point != null && radiusValue != null && validRadius)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _visible(point!),
                                radius: radiusValue!.clamp(0, 20037508),
                                useRadiusInMeter: true,
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .2),
                                borderColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        if (point != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _visible(point!),
                                width: 48,
                                height: 48,
                                child: Semantics(
                                  label: l.locationDragPin,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanUpdate: (details) => _pick(
                                      controller.camera.screenOffsetToLatLng(
                                        controller.camera.latLngToScreenOffset(
                                              _visible(point!),
                                            ) +
                                            details.delta,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_pin,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
            Flexible(
              flex: 0,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.locationDragPin),
                      if (point != null)
                        Text(
                          l.locationCoordinates(
                            point!.latitude.toStringAsFixed(6),
                            point!.longitude.toStringAsFixed(6),
                          ),
                        ),
                      if (offline) ...[
                        Text(l.locationOffline),
                        TextButton(
                          onPressed: () => setState(() {
                            offline = false;
                            retry++;
                          }),
                          child: Text(l.timelineRetry),
                        ),
                      ],
                      TextField(
                        controller: radius,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.locationRadius,
                          errorText: validRadius ? null : l.locationInvalid,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(locationPlatformProvider)
                                .openCopyright();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.locationUnavailable)),
                              );
                            }
                          }
                        },
                        child: Text(l.locationOsmAttribution),
                      ),
                      FilledButton(
                        onPressed: point == null || !validRadius
                            ? null
                            : () => Navigator.pop(
                                context,
                                LocationAnchor(
                                  point!.latitude,
                                  point!.longitude,
                                  radiusM: radiusValue,
                                ),
                              ),
                        child: Text(l.locationSave),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
