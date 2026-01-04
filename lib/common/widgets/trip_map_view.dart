import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:puked/models/db_models.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

// ==========================================
// 0. 坐标纠偏工具 (WGS84 -> GCJ02)
// ==========================================
class CoordConv {
  static const double pi = 3.1415926535897932384626;
  static const double a = 6378245.0;
  static const double ee = 0.00669342162296594323;

  static LatLng fix(double lat, double lng) {
    if (outOfChina(lat, lng)) return LatLng(lat, lng);
    double dLat = transformLat(lng - 105.0, lat - 35.0);
    double dLng = transformLon(lng - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * pi;
    double magic = math.sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = math.sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (a / sqrtMagic * math.cos(radLat) * pi);
    return LatLng(lat + dLat, lng + dLng);
  }

  static bool outOfChina(double lat, double lon) {
    if (lon < 72.004 || lon > 137.8347) return true;
    if (lat < 0.8293 || lat > 55.8271) return true;
    return false;
  }

  static double transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(x.abs());
    ret += (20.0 * math.sin(6.0 * x * pi) + 20.0 * math.sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * math.sin(y * pi) + 40.0 * math.sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * math.sin(y / 12.0 * pi) + 320 * math.sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double transformLon(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(x.abs());
    ret += (20.0 * math.sin(6.0 * x * pi) + 20.0 * math.sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * math.sin(x * pi) + 40.0 * math.sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * math.sin(x / 12.0 * pi) + 300.0 * math.sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }
}

// ==========================================
// 1. TileProvider
// ==========================================
class RetryTileProvider extends TileProvider {
  final int maxRetries;
  final Duration retryDelay;
  
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 30)
    ..maxConnectionsPerHost = 15; 

  RetryTileProvider({
    this.maxRetries = 3,
    this.retryDelay = const Duration(milliseconds: 300),
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return RetryNetworkImage(
      url,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      httpClient: _httpClient,
    );
  }
}

// ==========================================
// 2. NetworkImage
// ==========================================
class RetryNetworkImage extends ImageProvider<RetryNetworkImage> {
  final String url;
  final int maxRetries;
  final Duration retryDelay;
  final HttpClient httpClient;

  RetryNetworkImage(this.url,
      {required this.maxRetries,
      required this.retryDelay,
      required this.httpClient});

  @override
  Future<RetryNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<RetryNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      RetryNetworkImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<RetryNetworkImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
      RetryNetworkImage key, ImageDecoderCallback decode) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final uri = Uri.parse(url);
        final request = await httpClient.getUrl(uri);

        request.headers.set(HttpHeaders.userAgentHeader, 
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        
        final response = await request.close();
        if (response.statusCode == 403 || response.statusCode == 429) {
           throw Exception('Server blocked request: ${response.statusCode}');
        }
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (bytes.lengthInBytes == 0) throw Exception('Empty image');

        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return await decode(buffer);
        
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempt);
      }
    }
    throw Exception('Failed to load image');
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is RetryNetworkImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

// ==========================================
// 3. TripMapView
// ==========================================
class TripMapView extends StatefulWidget {
  final List<TrajectoryPoint> trajectory;
  final List<RecordedEvent> events;
  final bool isLive;
  final Position? currentPosition;
  final LatLng? focusPoint;
  
  // 🟢 核心修复：接受外部传入的 mapController
  final MapController? mapController; 

  const TripMapView({
    super.key,
    required this.trajectory,
    required this.events,
    this.isLive = true,
    this.currentPosition,
    this.focusPoint,
    this.mapController, // 🟢 新增
  });

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView>
    with TickerProviderStateMixin {
  late final MapController _mapController; // 改为 late final
  Timer? _recenterTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    // 🟢 如果外部传了就用外部的，否则自己新建
    _mapController = widget.mapController ?? MapController();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;
    
    final fixedDest = CoordConv.fix(destLocation.latitude, destLocation.longitude);

    final camera = _mapController.camera;
    final latTween = Tween<double>(
        begin: camera.center.latitude, end: fixedDest.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: fixedDest.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  List<Polyline> _buildPolylines() {
    if (widget.trajectory.isEmpty) return [];

    final List<Polyline> lines = [];
    List<LatLng> currentSegment = [];
    bool currentIsLowConf = widget.trajectory.first.isLowConfidence ?? false;

    // FSD 风格蓝
    const fsdBlue = Color(0xFF40C4FF); 
    final lowConfColor = Colors.orange.withValues(alpha: 0.5);

    for (var i = 0; i < widget.trajectory.length; i++) {
      final p = widget.trajectory[i];
      final fixedP = CoordConv.fix(p.lat, p.lng);
      
      final isLow = p.isLowConfidence ?? false;

      if (isLow != currentIsLowConf) {
        if (currentSegment.length >= 2) {
          lines.add(Polyline(
            points: List.from(currentSegment),
            color: currentIsLowConf ? lowConfColor : fsdBlue,
            strokeWidth: 4,
          ));
        }
        currentSegment = [
          currentSegment.isNotEmpty ? currentSegment.last : fixedP,
          fixedP
        ];
        currentIsLowConf = isLow;
      } else {
        currentSegment.add(fixedP);
      }
    }

    if (currentSegment.length >= 2) {
      lines.add(Polyline(
        points: currentSegment,
        color: currentIsLowConf ? lowConfColor : fsdBlue,
        strokeWidth: 4,
      ));
    }

    return lines;
  }

  @override
  void dispose() {
    _recenterTimer?.cancel();
    // 🟢 如果 Controller 是外部传进来的，不要在这里 dispose，由外部负责
    if (widget.mapController == null) {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _startRecenterTimer() {
    _recenterTimer?.cancel();
    _recenterTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && widget.isLive) {
        setState(() => _isUserInteracting = false);
        _recenterToCurrentLocation();
      }
    });
  }

  void _recenterToCurrentLocation() {
    if (!mounted) return;
    if (widget.currentPosition != null) {
      final fixedPos = CoordConv.fix(widget.currentPosition!.latitude, widget.currentPosition!.longitude);
      _mapController.move(fixedPos, _mapController.camera.zoom);
    } else if (widget.trajectory.isNotEmpty) {
      final last = widget.trajectory.last;
      final fixedLast = CoordConv.fix(last.lat, last.lng);
      _mapController.move(fixedLast, _mapController.camera.zoom);
    }
  }

  @override
  void didUpdateWidget(TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusPoint != null &&
        widget.focusPoint != oldWidget.focusPoint) {
      _animatedMapMove(widget.focusPoint!, 17.0);
    }

    if (widget.isLive && !_isUserInteracting) {
      // 🟢 如果外部控制了地图 (比如 Course Up)，这里就不需要重复 move 了
      // 但为了保险起见，或者为了非录制模式下的跟随，保留基本逻辑
      if (widget.mapController == null && 
         (widget.currentPosition != oldWidget.currentPosition ||
          widget.trajectory.length != oldWidget.trajectory.length)) {
        _recenterToCurrentLocation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng center = const LatLng(31.2304, 121.4737);
    
    if (widget.currentPosition != null) {
      center = CoordConv.fix(widget.currentPosition!.latitude, widget.currentPosition!.longitude);
    } else if (widget.trajectory.isNotEmpty) {
      if (widget.isLive) {
        final last = widget.trajectory.last;
        center = CoordConv.fix(last.lat, last.lng);
      } else {
        final points = widget.trajectory.map((p) => CoordConv.fix(p.lat, p.lng)).toList();
        if (points.isNotEmpty) {
             final bounds = LatLngBounds.fromPoints(points);
             center = bounds.center;
        }
      }
    }

    return Container(
      color: Colors.grey[900],
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
          maxZoom: 22.0, 
          minZoom: 3.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onPointerDown: (_, __) {
            if (widget.isLive) {
              setState(() => _isUserInteracting = true);
              _startRecenterTimer();
            }
          },
          onMapReady: () {
            if (!widget.isLive && widget.trajectory.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final points = widget.trajectory.map((p) => CoordConv.fix(p.lat, p.lng)).toList();
                if (points.isNotEmpty) {
                  final bounds = LatLngBounds.fromPoints(points);
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 16,
                    ),
                  );
                }
              });
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://wprd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&style=6&x={x}&y={y}&z={z}',
            subdomains: const ['1', '2', '3', '4'],
            tileProvider: RetryTileProvider(maxRetries: 5),
            maxNativeZoom: 18,
            maxZoom: 22,
            retinaMode: false,
            tileSize: 256,
            tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 300)),
            evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          ),
          TileLayer(
            urlTemplate: 'https://wprd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&style=8&x={x}&y={y}&z={z}',
            subdomains: const ['1', '2', '3', '4'],
            tileProvider: RetryTileProvider(maxRetries: 5),
            maxNativeZoom: 18,
            maxZoom: 22,
            retinaMode: false,
            tileSize: 256,
            evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          ),
          PolylineLayer(
            polylines: _buildPolylines(),
          ),
          MarkerLayer(
            markers: widget.events
                .map((e) {
                  if (e.lat != null && e.lng != null) {
                    final fixedE = CoordConv.fix(e.lat!, e.lng!);
                    final config = _getEventConfig(e.type);
                    return Marker(
                      point: fixedE,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          config.icon,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    );
                  }
                  return null;
                })
                .whereType<Marker>()
                .toList(),
          ),
          if (widget.trajectory.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                  point: CoordConv.fix(
                      widget.trajectory.first.lat, widget.trajectory.first.lng),
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 12),
                  ),
                ),
                if (!widget.isLive)
                  Marker(
                    point: CoordConv.fix(
                        widget.trajectory.last.lat, widget.trajectory.last.lng),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child:
                          const Icon(Icons.stop, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          if (widget.isLive &&
              (widget.currentPosition != null || widget.trajectory.isNotEmpty))
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: _CurrentLocationMarker(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  _EventUIConfig _getEventConfig(String type) {
    if (type.contains('Acceleration')) {
      return const _EventUIConfig(Icons.speed, Color(0xFFFF9500));
    } else if (type.contains('Deceleration')) {
      return const _EventUIConfig(Icons.trending_down, Color(0xFFFF3B30));
    } else if (type.contains('bump')) {
      return const _EventUIConfig(Icons.vibration, Color(0xFF5856D6));
    } else if (type.contains('wobble')) {
      return const _EventUIConfig(Icons.waves, Color(0xFF007AFF));
    }
    return const _EventUIConfig(Icons.warning, Colors.grey);
  }
}

class _EventUIConfig {
  final IconData icon;
  final Color color;
  const _EventUIConfig(this.icon, this.color);
}

class _CurrentLocationMarker extends StatefulWidget {
  @override
  State<_CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<_CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF40C4FF);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12 + (28 * _controller.value),
              height: 12 + (28 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.4 * (1 - _controller.value)),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}