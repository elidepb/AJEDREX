import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  // Private instance of FlutterBluetoothSerial
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Connection state notifier
  final ValueNotifier<BluetoothConnectionState> connectionStateNotifier =
      ValueNotifier(BluetoothConnectionState.disconnected);

  // Discovered devices notifier
  final ValueNotifier<List<BluetoothDevice>> discoveredDevicesNotifier =
      ValueNotifier([]);
  
  // Notifier for error messages
  final ValueNotifier<String?> currentErrorNotifier = ValueNotifier(null);

  // Bluetooth connection instance
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputStreamSubscription;

  // Stream controller for incoming data
  final StreamController<String> _incomingDataController =
      StreamController<String>.broadcast();

  // Stream for incoming data
  Stream<String> get incomingDataStream => _incomingDataController.stream;

  // Method to start discovery
  Future<void> startDiscovery() async {
    currentErrorNotifier.value = null; // Clear previous errors
    try {
      discoveredDevicesNotifier.value = []; // Clear previous results
      // Stop any existing discovery before starting a new one
      await _bluetooth.cancelDiscovery();
      if (kDebugMode) {
        print("Starting discovery...");
      }
      _bluetooth.startDiscovery().listen((r) {
        final existingIndex = discoveredDevicesNotifier.value
            .indexWhere((device) => device.address == r.device.address);
        if (existingIndex >= 0) {
          discoveredDevicesNotifier.value[existingIndex] = r.device;
        } else {
          discoveredDevicesNotifier.value = [
            ...discoveredDevicesNotifier.value,
            r.device
          ];
        }
      }).onDone(() {
        if (kDebugMode) {
          print("Discovery finished.");
        }
        // Optionally, notify that discovery is done if UI needs to know
      });
    } catch (e, s) {
      final errorMsg = "Error starting discovery: $e";
      if (kDebugMode) {
        print("$errorMsg\n$s");
      }
      currentErrorNotifier.value = errorMsg;
      // Discovery failure doesn't mean connection error, so don't set connectionStateNotifier here.
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    currentErrorNotifier.value = null;
    if (connectionStateNotifier.value == BluetoothConnectionState.connecting) {
        if (kDebugMode) {
            print("Connection attempt already in progress. Ignoring new attempt to ${device.address}.");
        }
        currentErrorNotifier.value = "Connection attempt already in progress.";
        return;
    }

    if (_connection != null && _connection!.isConnected) {
      if (kDebugMode) {
        print("Already connected. Disconnecting first to connect to ${device.address}.");
      }
      // Disconnect but don't set an error, as this is a user-initiated new connection.
      await disconnect(reason: "Switching connection to ${device.address}");
    }

    connectionStateNotifier.value = BluetoothConnectionState.connecting;
    if (kDebugMode) {
      print("Attempting to connect to ${device.name ?? 'Unknown device'} (${device.address})");
    }

    try {
      // Ensure discovery is not running which can interfere with connections.
      await _bluetooth.cancelDiscovery(); 
      if (kDebugMode) {
        print("Discovery cancelled before connecting.");
      }

      _connection = await BluetoothConnection.toAddress(device.address);
      connectionStateNotifier.value = BluetoothConnectionState.connected;
      currentErrorNotifier.value = null; // Clear error on successful connection
      if (kDebugMode) {
        print("Successfully connected to ${device.name ?? device.address}.");
      }

      // Cancel any existing subscription before creating a new one
      await _inputStreamSubscription?.cancel();
      _inputStreamSubscription = _connection!.input!.listen((Uint8List data) {
        final incomingMessage = utf8.decode(data);
        if (kDebugMode) {
          print("Received data: $incomingMessage");
        }
        _incomingDataController.add(incomingMessage);
      }, onDone: () {
        final message = "Disconnected: Remote host closed connection or stream ended.";
        if (kDebugMode) {
          print(message);
        }
        disconnect(isUnexpected: true, reason: message);
      }, onError: (error, stackTrace) {
        final errorMsg = "Stream error: $error";
        if (kDebugMode) {
          print("$errorMsg\n$stackTrace");
        }
        disconnect(isUnexpected: true, reason: errorMsg);
      });
      // Ensure that the subscription is cancelled if the connection object itself is disposed elsewhere
      _connection!.input!.handleError((error) {
           if (kDebugMode) print("Input stream error handler triggered: $error");
           disconnect(isUnexpected: true, reason: "Input stream error: $error");
      });

    } catch (e, s) {
      final errorMsg = "Connection failed to device ${device.address}: $e";
      if (kDebugMode) {
        print("$errorMsg\n$s");
      }
      currentErrorNotifier.value = errorMsg;
      connectionStateNotifier.value = BluetoothConnectionState.error;
      _connection = null; // Ensure connection is null on failure
    }
  }

  Future<void> disconnect({bool isUnexpected = false, String? reason}) async {
    final localReason = reason ?? (isUnexpected ? "Unexpected disconnection" : "User initiated disconnect");
    if (kDebugMode) {
      print("Disconnect called. Unexpected: $isUnexpected, Reason: $localReason. Current state: ${connectionStateNotifier.value}");
    }
    
    // If already disconnected and not due to an error being processed, nothing to do.
    if (connectionStateNotifier.value == BluetoothConnectionState.disconnected && !isUnexpected) {
        if (kDebugMode) print("Already disconnected. No action needed.");
        // currentErrorNotifier.value = localReason; // Update reason if provided
        return;
    }

    try {
      // Using ?. to safely call methods on potentially null _connection
      await _connection?.output?.close();
      // Cancel the stored subscription instead of trying to cancel via _connection.input
      await _inputStreamSubscription?.cancel();
      _inputStreamSubscription = null; // Nullify after cancelling
      await _connection?.finish(); // More robust than just close for some platforms/cases
      _connection?.dispose(); // Removed await
    } catch (e, s) {
      final errorMsg = "Error during disconnection resource cleanup: $e";
      if (kDebugMode) {
        print("$errorMsg\n$s");
      }
      // Don't override a more specific error if this is part of an unexpected disconnection
      // or if one is already set from a prior failure (e.g. sendData error)
      if (currentErrorNotifier.value == null || !isUnexpected) {
         currentErrorNotifier.value = currentErrorNotifier.value ?? errorMsg;
      }
    } finally {
      _connection = null; // Ensure it's null
      if (isUnexpected) {
        connectionStateNotifier.value = BluetoothConnectionState.error;
        // The 'reason' for an unexpected disconnect is the error itself.
        currentErrorNotifier.value = localReason; 
      } else {
        connectionStateNotifier.value = BluetoothConnectionState.disconnected;
        currentErrorNotifier.value = localReason; 
      }
      
      // Do not clear discovered devices here; let the UI or ViewModel manage that list.
      if (kDebugMode) {
        print("Disconnect finalized. State: ${connectionStateNotifier.value}, Reason/Error: ${currentErrorNotifier.value}");
      }
    }
  }

  void sendData(String data) {
    if (_connection != null && _connection!.isConnected) {
      try {
        if (kDebugMode) {
          print("Attempting to send data: $data");
        }
        _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
        // If `allSent` is awaited, this method becomes async.
        // await _connection!.output.allSent; 
        // currentErrorNotifier.value = null; // Clear error only if send is confirmed successful (e.g. via allSent)
      } catch (e, s) {
        final errorMsg = "Failed to send data: $e. Data: '$data'";
        if (kDebugMode) {
          print("$errorMsg\n$s");
        }
        // This error often means the connection is lost.
        disconnect(isUnexpected: true, reason: errorMsg);
        // Rethrow so ViewModel can also react to send failure specifically.
        throw Exception(errorMsg); 
      }
    } else {
      final errorMsg = "Cannot send data: No active or valid connection. Attempted to send: '$data'";
      if (kDebugMode) {
        print(errorMsg);
      }
      // If we thought we were connected, this is an unexpected state.
      if (connectionStateNotifier.value == BluetoothConnectionState.connected) {
         disconnect(isUnexpected: true, reason: "Attempted to send data while not truly connected.");
      } else {
        // If already disconnected/error, just update the error message.
        currentErrorNotifier.value = errorMsg;
        // Ensure state reflects error if not already disconnected.
        if (connectionStateNotifier.value != BluetoothConnectionState.disconnected) {
            connectionStateNotifier.value = BluetoothConnectionState.error;
        }
      }
      throw Exception(errorMsg);
    }
  }

  void dispose() {
    if (kDebugMode) {
      print("BluetoothService disposing...");
    }
    // Calling disconnect with a specific reason.
    // Using .then().catchError() for async operations in dispose.
    disconnect(reason: "Service disposed").catchError((e) {
        final errorMsg = "Error during dispose's disconnect: $e";
        if (kDebugMode) {
            print(errorMsg);
        }
        // Ensure state reflects error if dispose's disconnect fails critically
        if (connectionStateNotifier.value != BluetoothConnectionState.error) {
            connectionStateNotifier.value = BluetoothConnectionState.error;
        }
        currentErrorNotifier.value = currentErrorNotifier.value ?? errorMsg;
    }).whenComplete(() {
        // These are synchronous an can be called after disconnect attempt.
        _incomingDataController.close();
        connectionStateNotifier.dispose();
        discoveredDevicesNotifier.dispose();
        currentErrorNotifier.dispose(); // Dispose the new notifier
        if (kDebugMode) {
          print("BluetoothService fully disposed.");
        }
    });
  }
}

enum BluetoothConnectionState {
  disconnected, // Initial state, after explicit disconnect, or after a failed connection attempt that was reset.
  connecting,   // Actively attempting to establish a connection.
  connected,    // Connection successfully established and active.
  error,        // An unrecoverable error occurred (e.g., connection lost, critical send/receive failure).
}
