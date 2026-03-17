import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// --- CETAKAN DATA ---
class TaskItem {
  final String title;
  final DateTime date;
  bool isDone;
  TaskItem({required this.title, required this.date, this.isDone = false});
}

class FinanceItem {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome; 
  FinanceItem({required this.title, required this.amount, required this.date, required this.isIncome});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Super App Guratan',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDF8F5), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 231, 189, 146),
          primary: const Color.fromARGB(255, 229, 192, 166), 
          secondary: const Color.fromARGB(255, 237, 199, 172),
        ),
        fontFamily: 'sans-serif-rounded',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<String> _pageTitles = ['Kalender Tugas', 'Pomodoro Timer', 'Buku Keuangan'];

  // --- 1. MESIN KALENDER TUGAS ---
  DateTime _selectedDate = DateTime.now();
  final List<TaskItem> _allTasks = [];
  final TextEditingController _taskController = TextEditingController();

  List<TaskItem> get _tasksForSelectedDate => _allTasks.where((t) => 
    t.date.year == _selectedDate.year && t.date.month == _selectedDate.month && t.date.day == _selectedDate.day).toList();

  // --- 2. MESIN POMODORO ---
  Timer? _timer;
  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _resetTimer(); 
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _isBreak = false;
      _remainingTime = 25 * 60;
    });
  }

  void _toggleMode() { 
    _pauseTimer();
    setState(() {
      _isBreak = !_isBreak;
      _remainingTime = _isBreak ? 5 * 60 : 25 * 60;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // --- 3. MESIN KEUANGAN ---
  final List<FinanceItem> _finances = [];
  final TextEditingController _financeTitleController = TextEditingController();
  final TextEditingController _financeAmountController = TextEditingController();

  String _formatRp(double value) {
    String s = value.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) result = '.$result';
      result = s[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1)),
        backgroundColor: _currentIndex == 1 && _isBreak 
            ? const Color(0xFF8BA888) 
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      
      body: _buildBody(),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.brown.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: false,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Tugas'),
              BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Fokus'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Uang'),
            ],
          ),
        ),
      ),

      floatingActionButton: _currentIndex != 1 ? FloatingActionButton.extended(
        onPressed: _currentIndex == 0 ? _showAddTaskDialog : _showAddFinanceDialog, 
        label: Text(_currentIndex == 0 ? "Tugas" : "Catat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        icon: const Icon(Icons.add, color: Colors.white), 
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) return _buildCalendarPage();
    if (_currentIndex == 1) return _buildPomodoroPage();
    return _buildFinancePage();
  }

  // =========================================================================
  // RUANG 3: BUKU KEUANGAN PRO
  // =========================================================================
  Widget _buildFinancePage() {
    final now = DateTime.now();
    
    final daily = _finances.where((f) => f.date.year == now.year && f.date.month == now.month && f.date.day == now.day);
    final weekly = _finances.where((f) => now.difference(f.date).inDays <= 7);
    final monthly = _finances.where((f) => f.date.year == now.year && f.date.month == now.month);
    final yearly = _finances.where((f) => f.date.year == now.year);

    double sumIncome(Iterable<FinanceItem> list) => list.where((i) => i.isIncome).fold(0, (s, i) => s + i.amount);
    double sumExpense(Iterable<FinanceItem> list) => list.where((i) => !i.isIncome).fold(0, (s, i) => s + i.amount);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: [
              _buildFinanceCard("Hari Ini", sumIncome(daily), sumExpense(daily)),
              _buildFinanceCard("7 Hari Terakhir", sumIncome(weekly), sumExpense(weekly)),
              _buildFinanceCard("Bulan Ini", sumIncome(monthly), sumExpense(monthly)),
              _buildFinanceCard("Tahun Ini", sumIncome(yearly), sumExpense(yearly)),
            ],
          ),
        ),
        
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: _finances.isEmpty 
              ? Center(child: Text("Belum ada catatan keuangan ☕", style: TextStyle(color: Colors.brown[300])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _finances.length,
                  itemBuilder: (context, index) {
                    final actualIndex = _finances.length - 1 - index; // Ambil index aslinya
                    final item = _finances[actualIndex]; 
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.brown.withValues(alpha: 0.1))),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isIncome ? const Color(0xFF8BA888).withValues(alpha: 0.2) : const Color(0xFFE5989B).withValues(alpha: 0.2),
                          child: Icon(item.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                                      color: item.isIncome ? const Color(0xFF8BA888) : const Color(0xFFE5989B)),
                        ),
                        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
                        subtitle: Text("${item.date.day}/${item.date.month}/${item.date.year}", style: const TextStyle(fontSize: 12)),
                        // INI DIA TOMBOL HAPUSNYA!
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (item.isIncome ? "+ " : "- ") + _formatRp(item.amount),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: item.isIncome ? const Color(0xFF8BA888) : const Color(0xFFE5989B)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300]),
                              onPressed: () {
                                setState(() {
                                  _finances.removeAt(actualIndex); // Hapus data dari brankas
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, double income, double expense) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[400], fontSize: 14)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Pemasukan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(_formatRp(income), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8BA888))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text("Pengeluaran", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(_formatRp(expense), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5989B))),
              ]),
            ],
          )
        ],
      ),
    );
  }

  void _showAddFinanceDialog() {
    bool isIncome = false; 
    
    showDialog(context: context, builder: (context) {
      return StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFDF8F5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Text("Catat Keuangan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isIncome = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isIncome ? const Color(0xFF8BA888) : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                          ),
                          child: Center(child: Text("Pemasukan", style: TextStyle(color: isIncome ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isIncome = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isIncome ? const Color(0xFFE5989B) : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                          ),
                          child: Center(child: Text("Pengeluaran", style: TextStyle(color: !isIncome ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _financeTitleController, 
                  decoration: InputDecoration(
                    hintText: isIncome ? "Dapat dari mana duitnya?" : "Buat apa duitnya?", 
                    filled: true, 
                    fillColor: Colors.white, 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _financeAmountController, 
                  keyboardType: TextInputType.number, 
                  decoration: InputDecoration(hintText: "Berapa jumlahnya?", prefixText: "Rp ", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: TextStyle(color: Colors.brown[400]))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { 
                  if(_financeTitleController.text.isNotEmpty && _financeAmountController.text.isNotEmpty) {
                    setState(() {
                      _finances.add(FinanceItem(
                        title: _financeTitleController.text, 
                        amount: double.tryParse(_financeAmountController.text) ?? 0, 
                        date: DateTime.now(), 
                        isIncome: isIncome
                      ));
                    });
                    _financeTitleController.clear(); 
                    _financeAmountController.clear();
                    Navigator.pop(context); 
                  }
                }, 
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      );
    });
  }

  // =========================================================================
  // RUANG 2: POMODORO 
  // =========================================================================
  Widget _buildPomodoroPage() {
    double progress = _remainingTime / (_isBreak ? 5 * 60 : 25 * 60);
    Color themeColor = _isBreak ? const Color(0xFF8BA888) : Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(_isBreak ? "WAKTUNYA ISTIRAHAT ☕" : "FOKUS BELAJAR 🧠", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor)),
          ),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 250, height: 250, child: CircularProgressIndicator(value: progress, strokeWidth: 15, strokeCap: StrokeCap.round, color: themeColor, backgroundColor: Colors.white)),
              Text(_formatTime(_remainingTime), style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.brown[700])),
            ],
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.refresh_rounded, size: 35, color: Colors.brown[300]), onPressed: _resetTimer),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _isRunning ? _pauseTimer : _startTimer,
                child: Container(height: 80, width: 80, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]), child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 45, color: Colors.white)),
              ),
              const SizedBox(width: 20),
              IconButton(icon: Icon(Icons.skip_next_rounded, size: 35, color: Colors.brown[300]), onPressed: _toggleMode),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // RUANG 1: KALENDER TUGAS 
  // =========================================================================
  Widget _buildCalendarPage() {
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: CalendarDatePicker(initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), onDateChanged: (d) => setState(() => _selectedDate = d)),
      ),
      Expanded(
        child: _tasksForSelectedDate.isEmpty 
          ? Center(child: Text("Belum ada rencana hari ini ✨", style: TextStyle(color: Colors.brown[300], fontSize: 16))) 
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasksForSelectedDate.length,
              itemBuilder: (context, i) {
                final t = _tasksForSelectedDate[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.brown.withValues(alpha: 0.1))),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Checkbox(value: t.isDone, activeColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onChanged: (v) => setState(() => t.isDone = v!)),
                    title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w600, color: t.isDone ? Colors.grey : Colors.brown[700], decoration: t.isDone ? TextDecoration.lineThrough : null)),
                    trailing: IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300]), onPressed: () => setState(() => _allTasks.remove(t))),
                  ),
                );
              },
            ),
      )
    ]);
  }

  void _showAddTaskDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFFDF8F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Text("Tugas Baru", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
      content: TextField(controller: _taskController, autofocus: true, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: TextStyle(color: Colors.brown[400]))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () { setState(() => _allTasks.add(TaskItem(title: _taskController.text, date: _selectedDate))); _taskController.clear(); Navigator.pop(context); }, 
          child: const Text("Simpan", style: TextStyle(color: Colors.white)),
        )
      ],
    ));
  }
}