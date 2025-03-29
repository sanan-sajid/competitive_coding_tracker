import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contest Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: const TabBarTheme(
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contest Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.code), text: 'Codeforces'),
            Tab(icon: Icon(Icons.code), text: 'CodeChef'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CodeforcesContestsTab(),
          CodeChefContestsTab(),
          ProfileComparisonTab(),
        ],
      ),
    );
  }
}

// Codeforces Contests Tab
class CodeforcesContestsTab extends StatefulWidget {
  const CodeforcesContestsTab({Key? key}) : super(key: key);

  @override
  _CodeforcesContestsTabState createState() => _CodeforcesContestsTabState();
}

class _CodeforcesContestsTabState extends State<CodeforcesContestsTab> {
  List<dynamic> _contests = [];
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchCodeforcesContests();
  }

  Future<void> _fetchCodeforcesContests() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response =
          await http.get(Uri.parse('https://codeforces.com/api/contest.list'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _contests = data['result']
                .where((contest) => contest['phase'] == 'BEFORE')
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMsg = 'API Error: ${data['comment']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMsg = 'Failed to load contests: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]!
            : Colors.grey[300]!,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[500]!
            : Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Container(
                width: double.infinity, height: 16, color: Colors.white),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 12, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 100, height: 12, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContestCard(dynamic contest) {
    final startTimeSeconds = contest['startTimeSeconds'];
    final durationSeconds = contest['durationSeconds'];
    final startDateTime =
        DateTime.fromMillisecondsSinceEpoch(startTimeSeconds * 1000);
    final endDateTime = startDateTime.add(Duration(seconds: durationSeconds));
    final formattedStartDate =
        DateFormat('MMM dd, yyyy HH:mm').format(startDateTime);
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(contest['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starts: $formattedStartDate'),
            Text(
                'Duration: $hours hours${minutes > 0 ? ' $minutes minutes' : ''}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final eventTitle = contest['name'];
                final url = Uri.encodeFull(
                    'https://www.google.com/calendar/render?action=TEMPLATE&text=$eventTitle&dates=${startDateTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z/${endDateTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z');
                if (await canLaunch(url)) await launch(url);
              },
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: () async {
          final url = 'https://codeforces.com/contests/${contest['id']}';
          if (await canLaunch(url)) await launch(url);
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerList();
    } else if (_errorMsg.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMsg, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCodeforcesContests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_contests.isEmpty) {
      return const Center(child: Text('No upcoming contests found'));
    } else {
      return AnimationLimiter(
        child: ListView.builder(
          itemCount: _contests.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildContestCard(_contests[index]),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchCodeforcesContests,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }
}

// CodeChef Contests Tab
class CodeChefContestsTab extends StatefulWidget {
  const CodeChefContestsTab({Key? key}) : super(key: key);

  @override
  _CodeChefContestsTabState createState() => _CodeChefContestsTabState();
}

class _CodeChefContestsTabState extends State<CodeChefContestsTab> {
  List<dynamic> _contests = [];
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchCodeChefContests();
  }

  Future<void> _fetchCodeChefContests() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://clist.by/api/v4/json/contest/?upcoming=true&host=codechef.com'),
        headers: {
          'Authorization':
              ' ApiKey sanan:4bcdd0f9877805407184c31711f642a271d4808e',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _contests = data['objects'] ?? [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contests updated successfully')),
        );
      } else {
        setState(() {
          _errorMsg = 'Failed to load contests: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]!
            : Colors.grey[300]!,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[500]!
            : Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Container(
                width: double.infinity, height: 16, color: Colors.white),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 12, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 100, height: 12, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContestCard(dynamic contest) {
    final startTime = DateTime.parse(contest['start']);
    final endTime = DateTime.parse(contest['end']);
    final formattedStartDate =
        DateFormat('MMM dd, yyyy HH:mm').format(startTime);
    final duration = endTime.difference(startTime);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    String durationText = '';
    if (days > 0) durationText += '$days days ';
    if (hours > 0) durationText += '$hours hours ';
    if (minutes > 0) durationText += '$minutes minutes';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(contest['event']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starts: $formattedStartDate'),
            Text('Duration: $durationText'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final eventTitle = contest['event'];
                final url = Uri.encodeFull(
                    'https://www.google.com/calendar/render?action=TEMPLATE&text=$eventTitle&dates=${startTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z/${endTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z');
                if (await canLaunch(url)) await launch(url);
              },
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: () async {
          final url = contest['href'];
          if (await canLaunch(url)) await launch(url);
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerList();
    } else if (_errorMsg.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchCodeChefContests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_contests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text('No upcoming contests found'),
            ),
          ),
        ],
      );
    } else {
      return AnimationLimiter(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _contests.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildContestCard(_contests[index]),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchCodeChefContests,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }
}

// Profile Comparison Tab
class ProfileComparisonTab extends StatefulWidget {
  const ProfileComparisonTab({Key? key}) : super(key: key);

  @override
  _ProfileComparisonTabState createState() => _ProfileComparisonTabState();
}

class _ProfileComparisonTabState extends State<ProfileComparisonTab> {
  final TextEditingController _handle1Controller = TextEditingController();
  final TextEditingController _handle2Controller = TextEditingController();
  Map<String, dynamic>? _profile1;
  Map<String, dynamic>? _profile2;
  bool _isLoading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadSavedHandles();
  }

  Future<void> _loadSavedHandles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _handle1Controller.text = prefs.getString('handle1') ?? '';
      _handle2Controller.text = prefs.getString('handle2') ?? '';
    });
    if (_handle1Controller.text.isNotEmpty &&
        _handle2Controller.text.isNotEmpty) {
      _compareProfiles();
    }
  }

  Future<void> _saveHandles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('handle1', _handle1Controller.text);
    await prefs.setString('handle2', _handle2Controller.text);
  }

  Future<Map<String, dynamic>> _fetchUserInfo(String handle) async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/user.info?handles=$handle'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') return data['result'][0];
      throw Exception(data['comment']);
    }
    throw Exception('Failed to load profile: ${response.statusCode}');
  }

  Future<void> _compareProfiles() async {
    final handle1 = _handle1Controller.text.trim();
    final handle2 = _handle2Controller.text.trim();

    if (handle1.isEmpty || handle2.isEmpty) {
      setState(() {
        _errorMsg = 'Please enter both handles';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _profile1 = null;
      _profile2 = null;
    });

    try {
      final results = await Future.wait([
        _fetchUserInfo(handle1),
        _fetchUserInfo(handle2),
      ]);

      await _saveHandles();

      setState(() {
        _profile1 = results[0];
        _profile2 = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'newbie':
        return '#808080';
      case 'pupil':
        return '#008000';
      case 'specialist':
        return '#03a89e';
      case 'expert':
        return '#0000ff';
      case 'candidate master':
        return '#aa00aa';
      case 'master':
      case 'international master':
        return '#ff8c00';
      case 'grandmaster':
      case 'international grandmaster':
      case 'legendary grandmaster':
        return '#ff0000';
      default:
        return '#000000';
    }
  }

  Widget _buildShimmerComparison() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              highlightColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]!
                  : Colors.grey[100]!,
              child: Column(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 16, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
            ),
            Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              highlightColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]!
                  : Colors.grey[100]!,
              child: Column(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 16, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[500]!
              : Colors.grey[100]!,
          child: Container(height: 200, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildComparisonContent() {
    if (_isLoading) {
      return _buildShimmerComparison();
    } else if (_errorMsg.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMsg, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    } else if (_profile1 != null && _profile2 != null) {
      return SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileSummary(_profile1!),
                    const SizedBox(width: 16),
                    _buildProfileSummary(_profile2!),
                  ],
                ),
                const Divider(height: 32),
                _buildComparisonTable(),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProfileSummary(Map<String, dynamic> profile) {
    final handle = profile['handle'];
    final rank = profile['rank'] ?? 'Unrated';
    final rating = profile['rating'] ?? 0;
    final maxRating = profile['maxRating'] ?? 0;
    final titlePhoto = profile['titlePhoto'];

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(titlePhoto)),
          const SizedBox(height: 8),
          Text(handle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            rank,
            style: TextStyle(
              color: Color(
                  int.parse(_getRankColor(rank).substring(1, 7), radix: 16) +
                      0xFF000000),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text('Rating: $rating (max: $maxRating)'),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final comparisonPairs = [
      {
        'label': 'Current Rating',
        'value1': _profile1!['rating'] ?? 0,
        'value2': _profile2!['rating'] ?? 0
      },
      {
        'label': 'Max Rating',
        'value1': _profile1!['maxRating'] ?? 0,
        'value2': _profile2!['maxRating'] ?? 0
      },
      {
        'label': 'Contribution',
        'value1': _profile1!['contribution'] ?? 0,
        'value2': _profile2!['contribution'] ?? 0
      },
      {
        'label': 'Friend of',
        'value1': _profile1!['friendOfCount'] ?? 0,
        'value2': _profile2!['friendOfCount'] ?? 0
      },
      {
        'label': 'Registration (years)',
        'value1': DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(
                    (_profile1!['registrationTimeSeconds'] ?? 0) * 1000))
                .inDays ~/
            365,
        'value2': DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(
                    (_profile2!['registrationTimeSeconds'] ?? 0) * 1000))
                .inDays ~/
            365,
      },
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Metric',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_profile1!['handle'],
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_profile2!['handle'],
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...comparisonPairs.map((pair) {
          final value1 = pair['value1'] as num;
          final value2 = pair['value2'] as num;
          final isValue1Higher = value1 > value2;

          return TableRow(
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(pair['label'] as String)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value1.toString(),
                  style: TextStyle(
                      fontWeight:
                          isValue1Higher ? FontWeight.bold : FontWeight.normal,
                      color: isValue1Higher ? Colors.green : null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value2.toString(),
                  style: TextStyle(
                      fontWeight: !isValue1Higher && value1 != value2
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: !isValue1Higher && value1 != value2
                          ? Colors.green
                          : null),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _handle1Controller,
            decoration: const InputDecoration(
                labelText: 'Codeforces Handle 1', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _handle2Controller,
            decoration: const InputDecoration(
                labelText: 'Codeforces Handle 2', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _compareProfiles,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Text('Compare Profiles'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildComparisonContent(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _handle1Controller.dispose();
    _handle2Controller.dispose();
    super.dispose();
  }
}
