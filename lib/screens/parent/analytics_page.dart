// lib/screens/parent/analytics_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../controllers/parent_dashboard_controller.dart';
import '../../models/transaction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF5F5F5);
const _kDark = Color(0xFF252525);
const _kCard = Colors.white;

const _kSpendColor = Color(0xFF5B6AF9);
const _kTopUpColor = Color(0xFF6ED7A4);
const _kWithdrawColor = Color(0xFFFFA16C);

const _kCategoryColors = [
  Color(0xFF5B6AF9),
  Color(0xFF6ED7A4),
  Color(0xFFFFA16C),
  Color(0xFFFF6B9D),
  Color(0xFF50C8E8),
  Color(0xFFFFC94A),
  Color(0xFFB983FF),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _fmtMoney(double v) => 'RM ${NumberFormat('#,##0.00').format(v)}';

bool _isTopUp(String cat) =>
    cat.toLowerCase().contains('top-up') ||
    cat.toLowerCase().contains('top up');
bool _isWithdraw(String cat) => cat.toLowerCase().contains('withdraw');
bool _isSpend(String cat) => !_isTopUp(cat) && !_isWithdraw(cat);

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _ctrl = Get.find<ParentDashboardController>();

  // Period selector: 0 = 7 days, 1 = 30 days, 2 = 90 days
  int _periodIndex = 0;
  final _periods = [7, 30, 90];
  final _periodLabels = ['7 Days', '30 Days', '90 Days'];

  // Child filter: null = all children
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchAllTransactions();
    });
  }

  List<TransactionModel> get _transactions {
    final cutoff = DateTime.now().subtract(
      Duration(days: _periods[_periodIndex]),
    );
    return _ctrl.allTransactions.where((t) {
      final inPeriod = t.createdAt.isAfter(cutoff);
      final inChild = _selectedChildId == null || t.childId == _selectedChildId;
      return inPeriod && inChild;
    }).toList();
  }

  // ── Derived stats ──────────────────────────────────────────────────────────

  double get _totalSpend => _transactions
      .where((t) => _isSpend(t.category))
      .fold(0.0, (s, t) => s + t.amount);

  double get _totalTopUp => _transactions
      .where((t) => _isTopUp(t.category))
      .fold(0.0, (s, t) => s + t.amount);

  double get _totalWithdraw => _transactions
      .where((t) => _isWithdraw(t.category))
      .fold(0.0, (s, t) => s + t.amount);

  /// Returns daily net-spend buckets for the selected period, oldest→newest.
  List<_DayBucket> get _dailyBuckets {
    final days = _periods[_periodIndex];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buckets = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return _DayBucket(date: d, spend: 0, topUp: 0, withdraw: 0);
    });

    for (final tx in _transactions) {
      final txDay = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final diff = today.difference(txDay).inDays;
      if (diff < 0 || diff >= days) continue;
      final idx = days - 1 - diff;
      if (_isTopUp(tx.category)) {
        buckets[idx].topUp += tx.amount;
      } else if (_isWithdraw(tx.category)) {
        buckets[idx].withdraw += tx.amount;
      } else {
        buckets[idx].spend += tx.amount;
      }
    }
    return buckets;
  }

  /// Category breakdown for spend-only transactions.
  Map<String, double> get _categoryBreakdown {
    final map = <String, double>{};
    for (final tx in _transactions) {
      if (_isSpend(tx.category)) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    // Sort by value descending
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Per-child spending totals.
  Map<String, double> get _childSpend {
    final map = <String, double>{};
    for (final tx in _transactions) {
      if (_isSpend(tx.category)) {
        final name = tx.childName.isEmpty ? 'Unknown' : tx.childName;
        map[name] = (map[name] ?? 0) + tx.amount;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Day-of-week spend pattern (0=Mon…6=Sun).
  List<double> get _weekdayPattern {
    final totals = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    for (final tx in _transactions) {
      if (_isSpend(tx.category)) {
        final wd = (tx.createdAt.weekday - 1) % 7; // 0=Mon
        totals[wd] += tx.amount;
        counts[wd]++;
      }
    }
    return List.generate(7, (i) => counts[i] == 0 ? 0 : totals[i]);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Obx(() {
          if (_ctrl.isLoadingAll.value && _ctrl.allTransactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: _kDark),
            );
          }
          return RefreshIndicator(
            color: _kDark,
            onRefresh: () => _ctrl.fetchAllTransactions(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(),
                _buildPeriodSelector(),
                _buildChildFilter(),
                _buildSummaryRow(),
                _buildSpendingTrendChart(),
                _buildCategoryPieChart(),
                _buildCategoryBreakdownList(),
                _buildChildComparisonBars(),
                _buildWeekdayHeatmap(),
                _buildTopMerchants(),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Row(
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Rounded',
                color: _kDark,
              ),
            ),
            const Spacer(),
            // Container(
            //   padding: const EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: _kCard,
            //     borderRadius: BorderRadius.circular(12),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.05),
            //         blurRadius: 8,
            //       ),
            //     ],
            //   ),
            //   child: const Icon(
            //     Icons.bar_chart_rounded,
            //     color: _kDark,
            //     size: 22,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // ── Period Selector ────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildPeriodSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(_periodLabels.length, (i) {
              final selected = _periodIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _periodIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selected ? _kDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _periodLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey[600],
                        fontFamily: 'SF Pro Rounded',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Child Filter ───────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildChildFilter() {
    final children = _ctrl.childrenList;
    if (children.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          children: [
            _filterChip(
              'All',
              _selectedChildId == null,
              () => setState(() => _selectedChildId = null),
            ),
            ...children.map(
              (c) => _filterChip(
                c.childNickname.isEmpty ? c.childName : c.childNickname,
                _selectedChildId == c.childId,
                () => setState(() => _selectedChildId = c.childId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _kDark : _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kDark : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
            fontFamily: 'SF Pro Rounded',
          ),
        ),
      ),
    );
  }

  // ── Summary Row ────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildSummaryRow() {
    final txCount = _transactions.length;
    final avgSpendPerDay = _periods[_periodIndex] > 0
        ? _totalSpend / _periods[_periodIndex]
        : 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big spend card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF252525), Color(0xFF3A3A3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kDark.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spending',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'SF Pro Rounded',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmtMoney(_totalSpend),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'SF Pro Rounded',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStat(
                        'Avg/Day',
                        _fmtMoney(avgSpendPerDay),
                        Icons.trending_up_rounded,
                      ),
                      const SizedBox(width: 24),
                      _miniStat(
                        'Transactions',
                        '$txCount',
                        Icons.receipt_long_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Top-Ups',
                    _fmtMoney(_totalTopUp),
                    Icons.add_circle_outline_rounded,
                    _kTopUpColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    'Withdrawals',
                    _fmtMoney(_totalWithdraw),
                    Icons.remove_circle_outline_rounded,
                    _kWithdrawColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontFamily: 'SF Pro Rounded',
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Rounded',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Rounded',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Spending Trend Line/Bar Chart ──────────────────────────────────────────

  SliverToBoxAdapter _buildSpendingTrendChart() {
    final buckets = _dailyBuckets;
    if (buckets.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Spending Trend',
        subtitle: _periodLabels[_periodIndex],
        child: SizedBox(
          height: 180,
          child: _TrendChart(buckets: buckets, period: _periods[_periodIndex]),
        ),
      ),
    );
  }

  // ── Category Pie Chart ─────────────────────────────────────────────────────

  SliverToBoxAdapter _buildCategoryPieChart() {
    final data = _categoryBreakdown;
    if (data.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Spending by Category',
        subtitle: 'Breakdown',
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: SizedBox(height: 180, child: _PieChart(data: data)),
            ),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: data.entries.take(5).toList().asMap().entries.map((
                  e,
                ) {
                  final color =
                      _kCategoryColors[e.key % _kCategoryColors.length];
                  final pct = _totalSpend > 0
                      ? (e.value.value / _totalSpend * 100).toStringAsFixed(1)
                      : '0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value.key,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kDark,
                              fontFamily: 'SF Pro Rounded',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Breakdown List ────────────────────────────────────────────────

  SliverToBoxAdapter _buildCategoryBreakdownList() {
    final data = _categoryBreakdown;
    if (data.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Category Detail',
        subtitle: '${data.length} categories',
        child: Column(
          children: data.entries.toList().asMap().entries.map((e) {
            final color = _kCategoryColors[e.key % _kCategoryColors.length];
            final pct = _totalSpend > 0 ? e.value.value / _totalSpend : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kDark,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                      ),
                      Text(
                        _fmtMoney(e.value.value),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Child Comparison Bar Chart ─────────────────────────────────────────────

  SliverToBoxAdapter _buildChildComparisonBars() {
    final data = _childSpend;
    if (data.length < 2) return const SliverToBoxAdapter(child: SizedBox());

    final maxVal = data.values.reduce(max);

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Spending per Child',
        subtitle: 'Comparison',
        child: Column(
          children: data.entries.toList().asMap().entries.map((e) {
            final color = _kCategoryColors[e.key % _kCategoryColors.length];
            final pct = maxVal > 0 ? e.value.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      e.value.key,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kDark,
                        fontFamily: 'SF Pro Rounded',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 72,
                    child: Text(
                      _fmtMoney(e.value.value),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'SF Pro Rounded',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Weekday Heatmap ────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildWeekdayHeatmap() {
    final pattern = _weekdayPattern;
    final maxVal = pattern.reduce(max);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Spending by Day',
        subtitle: 'Weekly pattern',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(7, (i) {
                final pct = maxVal > 0 ? pattern[i] / maxVal : 0.0;
                final isWeekend = i >= 5;
                final color = isWeekend ? _kWithdrawColor : _kSpendColor;
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: pct < 0.04 ? 0.04 : pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isWeekend ? _kWithdrawColor : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            if (maxVal > 0)
              _insightChip(
                _spendingDayInsight(pattern, days),
                Icons.lightbulb_outline_rounded,
              ),
          ],
        ),
      ),
    );
  }

  String _spendingDayInsight(List<double> pattern, List<String> days) {
    double maxV = 0;
    int maxIdx = 0;
    for (var i = 0; i < pattern.length; i++) {
      if (pattern[i] > maxV) {
        maxV = pattern[i];
        maxIdx = i;
      }
    }
    return 'Most spending happens on ${days[maxIdx]}s';
  }

  // ── Top Merchants ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildTopMerchants() {
    final merchants = <String, double>{};
    for (final tx in _transactions) {
      if (_isSpend(tx.category) && tx.merchantName.isNotEmpty) {
        merchants[tx.merchantName] =
            (merchants[tx.merchantName] ?? 0) + tx.amount;
      }
    }
    if (merchants.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final sorted = merchants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxVal = top.first.value;

    return SliverToBoxAdapter(
      child: _SectionCard(
        title: 'Top Merchants',
        subtitle: 'By spending',
        child: Column(
          children: top.asMap().entries.map((e) {
            final color = _kCategoryColors[e.key % _kCategoryColors.length];
            final pct = maxVal > 0 ? e.value.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFamily: 'SF Pro Rounded',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.value.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                            fontFamily: 'SF Pro Rounded',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _fmtMoney(e.value.value),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'SF Pro Rounded',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _insightChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _kDark.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kDark.withOpacity(0.6)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: _kDark.withOpacity(0.7),
                fontFamily: 'SF Pro Rounded',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data bucket
// ─────────────────────────────────────────────────────────────────────────────

class _DayBucket {
  final DateTime date;
  double spend;
  double topUp;
  double withdraw;
  _DayBucket({
    required this.date,
    this.spend = 0,
    this.topUp = 0,
    this.withdraw = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend Chart (custom painter bar/line hybrid)
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.buckets, required this.period});

  final List<_DayBucket> buckets;
  final int period;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(buckets: buckets, period: period),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<_DayBucket> buckets;
  final int period;

  _TrendPainter({required this.buckets, required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    const labelH = 22.0;
    const topPad = 8.0;
    final chartH = size.height - labelH - topPad;
    final barW = (size.width / buckets.length) * 0.55;

    final maxVal = buckets.map((b) => b.spend).reduce(max);
    if (maxVal == 0) return;

    final barPaint = Paint()
      ..color = _kSpendColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = _kSpendColor.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = _kSpendColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 1;

    // Grid lines
    for (int i = 1; i <= 3; i++) {
      final y = topPad + chartH - (chartH * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    bool pathStarted = false;
    final List<Offset> points = [];

    for (int i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final x = (i + 0.5) * (size.width / buckets.length);
      final barH = (b.spend / maxVal) * chartH;
      final y = topPad + chartH - barH;

      // Bar
      final rect = Rect.fromLTWH(
        x - barW / 2,
        topPad + chartH - barH,
        barW,
        barH,
      );
      final rr = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final barColor = b.spend == maxVal
          ? _kSpendColor
          : _kSpendColor.withOpacity(0.35);
      canvas.drawRRect(rr, barPaint..color = barColor);

      final dotY = y;
      points.add(Offset(x, dotY));
      if (!pathStarted) {
        path.moveTo(x, dotY);
        pathStarted = true;
      } else {
        // Smooth curve
        final prev = points[points.length - 2];
        final cp1 = Offset((prev.dx + x) / 2, prev.dy);
        final cp2 = Offset((prev.dx + x) / 2, dotY);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, x, dotY);
      }
    }

    // Draw line
    canvas.drawPath(path, linePaint);

    // Dots on line
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }

    // X-axis labels
    final step = period <= 7
        ? 1
        : period <= 30
        ? 7
        : 14;
    for (int i = 0; i < buckets.length; i++) {
      if (i % step != 0) continue;
      final x = (i + 0.5) * (size.width / buckets.length);
      final label = period <= 7
          ? DateFormat('EEE').format(buckets[i].date)
          : DateFormat('d/M').format(buckets[i].date);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.buckets != buckets || old.period != period;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pie Chart (custom painter)
// ─────────────────────────────────────────────────────────────────────────────

class _PieChart extends StatelessWidget {
  const _PieChart({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PiePainter(data: data),
      child: const SizedBox.expand(),
    );
  }
}

class _PiePainter extends CustomPainter {
  final Map<String, double> data;
  _PiePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - 8;
    const startAngle = -pi / 2;

    double currentAngle = startAngle;
    final entries = data.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final sweep = 2 * pi * (entries[i].value / total);
      final color = _kCategoryColors[i % _kCategoryColors.length];

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 28 : 22
        ..color = color
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(cx, cy),
          radius: radius - (i > 0 ? 0 : 0),
        ),
        currentAngle + 0.03,
        sweep - 0.06,
        false,
        paint,
      );

      currentAngle += sweep;
    }

    // Center text
    final topEntry = entries.first;
    final pct = (topEntry.value / total * 100).toStringAsFixed(0);
    final tp = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$pct%\n',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
          TextSpan(
            text: topEntry.key,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.2);
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.data != data;
}
