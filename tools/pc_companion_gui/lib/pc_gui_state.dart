import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PcGuiState extends ChangeNotifier {
  // Server state
  bool _isListening = false;
  bool _isConnected = false;
  int _port = 8765;
  String _statusMessage = 'Not connected';
  List<String> _log = [];
  ServerSocket? _serverSocket;
  bool _typeIntoActiveApp = true;

  // Getters
  bool get isListening => _isListening;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  List<String> get log => _log;
  int get port => _port;

  // Initialize
  PcGuiState() {
    _loadSettings();
  }

  // Start listening for connections
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _isListening = true;
      _statusMessage = 'Listening on port $_port';
      _addLog('Started listening on port $_port');
      notifyListeners();

      // Handle incoming connections
      await for (final socket in _serverSocket!) {
        _handleClient(socket);
      }
    } catch (e) {
      _statusMessage = 'Error starting server: $e';
      _addLog('Error starting server: $e');
      _isListening = false;
      notifyListeners();
      Fluttertoast.showToast(
        msg: 'Failed to start server: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Stop listening
  void stopListening() {
    if (!_isListening) return;

    _serverSocket?.close();
    _isListening = false;
    _isConnected = false;
    _statusMessage = 'Not connected';
    _addLog('Stopped listening');
    notifyListeners();
  }

  // Handle client connection
  Future<void> _handleClient(Socket socket) async {
    final remote = '${socket.remoteAddress.address}:${socket.remotePort}';
    _addLog('Connected: $remote');
    _isConnected = true;
    _statusMessage = 'Connected to $remote';
    notifyListeners();

    try {
      await for (final line in utf8.decoder.bind(socket).transform(const LineSplitter())) {
        final barcode = _extractBarcode(line);
        if (barcode != null && barcode.isNotEmpty) {
          _addLog('Received barcode: $barcode');
          if (_typeIntoActiveApp) {
            _sendToActiveApp(barcode);
          }
        }
      }
    } catch (error) {
      _addLog('Connection error from $remote: $error');
    } finally {
      _isConnected = false;
      _statusMessage = 'Listening on port $_port';
      _addLog('Disconnected: $remote');
      notifyListeners();
      await socket.close();
    }
  }

  // Extract barcode from JSON line
  String? _extractBarcode(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map) {
        return decoded['barcode']?.toString();
      }
    } catch (_) {
      return line.trim();
    }
    return line.trim();
  }

  // Send barcode to active application
  void _sendToActiveApp(String barcode) {
    // This would be implemented based on platform
    // For now, we just log it
    _addLog('Typing barcode into active app: $barcode');
  }

  // Add log entry
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    _log.insert(0, '[$timestamp] $message');
    if (_log.length > 50) {
      _log.removeLast();
    }
    notifyListeners();
  }

  // Load settings from storage (simplified)
  void _loadSettings() {
    // In a real app, this would load from persistent storage
  }

  // Save settings to storage (simplified)
  void _saveSettings() {
    // In a real app, this would save to persistent storage
  }

  // Toggle typing into active app
  void toggleTypeIntoActiveApp() {
    _typeIntoActiveApp = !_typeIntoActiveApp;
    _addLog('Type into active app: $_typeIntoActiveApp');
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}