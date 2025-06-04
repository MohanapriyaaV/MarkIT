import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/attendance_overview_service.dart';
import '../models/attendance_overview_model.dart';

class AttendanceOverviewScreen extends StatefulWidget {
  final String empId;
  
  const AttendanceOverviewScreen({Key? key, required this.empId}) : super(key: key);

  @override
  _AttendanceOverviewScreenState createState() => _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  AttendanceOverviewData? overviewData;
  bool isLoading = true;
  String? error;
  String selectedMetric = 'rate';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final data = await AttendanceOverviewService.getAttendanceOverview(widget.empId);
      setState(() {
        overviewData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6EC6E8), // Light blue
              Color(0xFF8B7ED8), // Purple
              Color(0xFF9B59B6), // Darker purple
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isLoading ? _buildLoading() : 
                       error != null ? _buildError() : 
                       _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Attendance Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Unknown error occurred',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8B7ED8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildMetricCards(),
            const SizedBox(height: 20),
            _buildCharts(),
            const SizedBox(height: 20),
            _buildCalendar(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7ED8), Color(0xFF6EC6E8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your performance and trends',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B7ED8).withOpacity(0.1),
                  const Color(0xFF6EC6E8).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF8B7ED8),
                ),
                const SizedBox(width: 8),
                Text(
                  'This Month',
                  style: TextStyle(
                    color: const Color(0xFF8B7ED8),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          'Attendance Rate',
          '${overviewData!.currentMonthRate.toStringAsFixed(1)}%',
          const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
          Icons.trending_up,
          overviewData!.monthOverMonthChange,
        ),
        _buildMetricCard(
          'Punctuality Score',
          '${overviewData!.punctualityScore.toStringAsFixed(1)}%',
          const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
          Icons.schedule,
          null,
        ),
        _buildMetricCard(
          'Days Present',
          '${overviewData!.currentMonthAttendedDays}',
          const LinearGradient(colors: [Color(0xFF3182ce), Color(0xFF63b3ed)]),
          Icons.check_circle,
          null,
          subtitle: 'of ${overviewData!.currentMonthWorkingDays} days',
        ),
        _buildMetricCard(
          'Early Arrivals',
          '${overviewData!.earlyAttendanceCount}',
          const LinearGradient(colors: [Color(0xFFed8936), Color(0xFFfbb040)]),
          Icons.wb_sunny,
          null,
          subtitle: 'sessions',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, LinearGradient gradient,
      IconData icon, double? change, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: change >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${change.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: change >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      children: [
        _buildTrendChart(),
        const SizedBox(height: 20),
        _buildPieChart(),
      ],
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                'Monthly Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Row(
                children: ['rate', 'days', 'sessions'].map((metric) => 
                  GestureDetector(
                    onTap: () => setState(() => selectedMetric = metric),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selectedMetric == metric 
                          ? const LinearGradient(colors: [Color(0xFF8B7ED8), Color(0xFF6EC6E8)])
                          : null,
                        color: selectedMetric != metric ? Colors.grey.shade100 : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        metric.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedMetric == metric ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        'M${value.toInt() + 1}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: overviewData!.monthlyTrends.asMap().entries.map((entry) {
                      double value = selectedMetric == 'rate' ? entry.value.attendanceRate :
                                   selectedMetric == 'days' ? entry.value.totalAttendedDays.toDouble() :
                                   entry.value.totalSessions.toDouble();
                      return FlSpot(entry.key.toDouble(), value);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF8B7ED8), Color(0xFF6EC6E8)]),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF8B7ED8),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B7ED8).withOpacity(0.3),
                          const Color(0xFF6EC6E8).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final presentDays = overviewData!.currentMonthAttendedDays;
    final absentDays = overviewData!.currentMonthWorkingDays - presentDays;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Attendance Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: presentDays.toDouble(),
                    color: const Color(0xFF38ef7d),
                    title: '$presentDays',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: absentDays.toDouble(),
                    color: const Color(0xFFff7675),
                    title: '$absentDays',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPieLegendItem('Present Days', const Color(0xFF38ef7d), presentDays),
              _buildPieLegendItem('Absent Days', const Color(0xFFff7675), absentDays),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(String label, Color color, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Month Calendar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          _buildCalendarGrid(),
          const SizedBox(height: 20),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Column(
      children: [
        // Weekday headers
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overviewData!.recentTrends.length,
          itemBuilder: (context, index) {
            final dayData = overviewData!.recentTrends[index];
            final dayNum = int.parse(dayData.date.split('-').last);
            final today = DateTime.now();
            final dayDate = DateTime.parse(dayData.date);
            final isToday = dayDate.day == today.day && dayDate.month == today.month;
            final isSunday = dayDate.weekday == 7;
            
            Color bgColor = Colors.grey.shade100;
            if (isSunday) {
              bgColor = Colors.grey.shade300;
            } else if (dayData.fnAttended && dayData.anAttended) {
              bgColor = const Color(0xFF38ef7d);
            } else if (dayData.fnAttended || dayData.anAttended) {
              bgColor = const Color(0xFFfbb040);
            } else if (dayDate.isBefore(today)) {
              bgColor = const Color(0xFFff7675);
            }

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: isToday ? Border.all(color: const Color(0xFF8B7ED8), width: 2) : null,
                boxShadow: isToday ? [
                  BoxShadow(
                    color: const Color(0xFF8B7ED8).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        color: isSunday || bgColor == Colors.grey.shade100
                            ? Colors.grey.shade600
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (dayData.hasEarlyAttendance)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildCalendarLegendItem('Full Day', const Color(0xFF38ef7d)),
          _buildCalendarLegendItem('Half Day', const Color(0xFFfbb040)),
          _buildCalendarLegendItem('Absent', const Color(0xFFff7675)),
          _buildCalendarLegendItem('Holiday', Colors.grey.shade300),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Early Arrival',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}