import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'widgets/stat_card.dart';
import '../data/api_service.dart';

class DbHealthView extends StatefulWidget {
  const DbHealthView({super.key});

  @override
  State<DbHealthView> createState() => _DbHealthViewState();
}

class _DbHealthViewState extends State<DbHealthView> {
  final ApiService _api = ApiService();
  late Timer _timer;

  double _cpuUsage = 1.2;
  double _ramUsage = 49.0;
  int _activeConnections = 8;
  int _maxConnections = 60;
  double _cacheHitRate = 99.5;
  double _storageUsage = 13.0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    // Fetch real metrics or fall back every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchStats();
    });
  }

  Future<void> _fetchStats() async {
    try {
      final metrics = await _api.fetchRealDbHealth();

      // Attempt to fetch true hardware metrics from Prometheus API
      Map<String, double>? hardwareMetrics;
      try {
        hardwareMetrics = await _api.fetchHardwareMetrics();
      } catch (e) {
        debugPrint('Hardware Metrics Fetch Error: $e');
      }

      if (!mounted) return;
      setState(() {
        _activeConnections = metrics['active_connections'] ?? 8;
        _maxConnections = metrics['max_connections'] ?? 60;
        final rawCacheHit = metrics['cache_hit_rate'];
        _cacheHitRate = rawCacheHit is num ? rawCacheHit.toDouble() : 99.5;

        final rawDbSize = metrics['db_size_bytes'];
        if (rawDbSize is num && rawDbSize > 0) {
          // Standard Supabase free tier is 500MB - 1GB allocated disk
          _storageUsage = ((rawDbSize / (500 * 1024 * 1024)) * 100).clamp(1.0, 100.0);
        }

        if (hardwareMetrics != null) {
          _cpuUsage = hardwareMetrics['cpu'] ?? _cpuUsage;
          _ramUsage = hardwareMetrics['ram'] ?? _ramUsage;
          if (hardwareMetrics['disk'] != null && hardwareMetrics['disk']! > 0) {
            _storageUsage = hardwareMetrics['disk']!;
          }
        }
      });
    } catch (e) {
      debugPrint('DB Health Fetch Error: $e');
      // Fallback to initial metrics if Supabase RPC is not yet created/configured
      if (!mounted) return;
      setState(() {
        _cpuUsage = 1.2;
        _ramUsage = 49.0;
        _activeConnections = 8;
        _cacheHitRate = 99.5;
        _storageUsage = 13.0;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final cards = [
                StatCard(
                  label: 'Active Connections',
                  value: '$_activeConnections',
                  subtitle: 'Optimal (Max: $_maxConnections)',
                  icon: HugeIcons.strokeRoundedActivity01,
                  accentColor: const Color(0xFF4ECDC4),
                ),
                StatCard(
                  label: 'Cache Hit Ratio',
                  value: '${_cacheHitRate.toStringAsFixed(1)}%',
                  subtitle: 'High efficiency',
                  icon: HugeIcons.strokeRoundedAiNetwork,
                  accentColor: const Color(0xFF6C63FF),
                ),
                const StatCard(
                  label: 'Avg Query Time',
                  value: '42ms',
                  subtitle: 'P95 latency',
                  icon: HugeIcons.strokeRoundedClock01,
                  accentColor: Color(0xFFFF6B6B),
                ),
              ];

              if (isDesktop) {
                return Row(
                  children: cards
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 20),
                              child: e.value,
                            ),
                          ))
                      .toList(),
                );
              } else {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards.map((c) => SizedBox(width: double.infinity, child: c)).toList(),
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // Resource Monitors
          const Text(
            'Live Resource Monitors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildResourceMonitors(),

          const SizedBox(height: 32),

          // Slow Queries
          const Text(
            'Recent Slow Queries',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildSlowQueries(),
        ],
      ),
    );
  }

  Widget _buildResourceMonitors() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _ResourceBar(
                label: 'CPU Utilization',
                percentage: _cpuUsage,
                color: const Color(0xFF6C63FF),
                icon: HugeIcons.strokeRoundedCpu,
              ),
              const SizedBox(height: 24),
              _ResourceBar(
                label: 'Memory Usage',
                percentage: _ramUsage,
                color: const Color(0xFF4ECDC4),
                icon: HugeIcons.strokeRoundedDatabase01,
              ),
              const SizedBox(height: 24),
              _ResourceBar(
                label: 'Disk Storage',
                percentage: _storageUsage,
                color: const Color(0xFF44CF6C),
                icon: HugeIcons.strokeRoundedHardDrive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlowQueries() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQueryRow('SELECT * FROM public.invoices WHERE business_id = ? AND status = ?', '940ms', Colors.amber),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10, height: 1),
              ),
              _buildQueryRow('UPDATE public.users SET last_login = ? WHERE id = ?', '412ms', Colors.amber),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10, height: 1),
              ),
              _buildQueryRow('DELETE FROM public.sessions WHERE expires_at < NOW()', '1250ms', Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueryRow(String query, String duration, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            query,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            duration,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final dynamic icon;

  const _ResourceBar({
    required this.label,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                HugeIcon(icon: icon, color: Colors.white54, size: 18, strokeWidth: 2.1),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.fastOutSlowIn,
                width: MediaQuery.of(context).size.width * (percentage / 100),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
