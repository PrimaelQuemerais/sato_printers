package io.svnk.sato_printers

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.svnk.sato_printers.handlers.ConnectionHandler
import io.svnk.sato_printers.handlers.DiscoveryHandler
import io.svnk.sato_printers.handlers.PrintHandler
import io.svnk.sato_printers.managers.PrinterManager

/**
 * SatoPrintersPlugin - Flutter plugin for SATO label printers.
 *
 * This plugin provides methods for:
 * - Discovering available printers (Bluetooth, USB)
 * - Connecting to printers (Bluetooth, TCP/IP, USB)
 * - Printing raw data and images
 * - Querying printer status
 */
class SatoPrintersPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "sato_printers"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var printerManager: PrinterManager
    private lateinit var discoveryHandler: DiscoveryHandler
    private lateinit var connectionHandler: ConnectionHandler
    private lateinit var printHandler: PrintHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        // Initialize managers
        printerManager = PrinterManager(context)

        // Initialize handlers
        discoveryHandler = DiscoveryHandler(context)
        connectionHandler = ConnectionHandler(printerManager)
        printHandler = PrintHandler(printerManager)

        // Set up method channel
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // Platform info
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            // Discovery methods
            "discoverBluetoothPrinters" -> {
                discoveryHandler.discoverBluetoothPrinters(result)
            }
            "discoverUsbPrinters" -> {
                discoveryHandler.discoverUsbPrinters(result)
            }
            "checkBluetoothStatus" -> {
                discoveryHandler.checkBluetoothStatus(result)
            }

            // Connection methods
            "connectBluetooth" -> {
                val address = call.argument<String>("address")
                    ?: return result.error("INVALID_ARGUMENT", "address is required", null)
                val timeout = call.argument<Int>("timeout") ?: 10000
                connectionHandler.connectBluetooth(address, timeout, result)
            }
            "connectTcp" -> {
                val ipAddress = call.argument<String>("ipAddress")
                    ?: return result.error("INVALID_ARGUMENT", "ipAddress is required", null)
                val port = call.argument<Int>("port")
                    ?: return result.error("INVALID_ARGUMENT", "port is required", null)
                val timeout = call.argument<Int>("timeout") ?: 10000
                connectionHandler.connectTcp(ipAddress, port, timeout, result)
            }
            "connectUsb" -> {
                val serialNumber = call.argument<String>("serialNumber")
                    ?: return result.error("INVALID_ARGUMENT", "serialNumber is required", null)
                connectionHandler.connectUsb(serialNumber, result)
            }
            "disconnect" -> {
                connectionHandler.disconnect(result)
            }
            "isConnected" -> {
                connectionHandler.isConnected(result)
            }
            "getCurrentDevice" -> {
                connectionHandler.getCurrentDevice(result)
            }

            // Print methods
            "printRawData" -> {
                val data = call.argument<ByteArray>("data")
                    ?: return result.error("INVALID_ARGUMENT", "data is required", null)
                val options = call.argument<Map<String, Any?>>("options")
                printHandler.printRawData(data, options, result)
            }
            "printImage" -> {
                val imageBytes = call.argument<ByteArray>("imageBytes")
                    ?: return result.error("INVALID_ARGUMENT", "imageBytes is required", null)
                val options = call.argument<Map<String, Any?>>("options")
                printHandler.printImage(imageBytes, options, result)
            }
            "getStatus" -> {
                printHandler.getStatus(result)
            }
            "setReadTimeout" -> {
                val timeout = call.argument<Int>("timeout")
                    ?: return result.error("INVALID_ARGUMENT", "timeout is required", null)
                printHandler.setReadTimeout(timeout, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Clean up
        printerManager.disconnect()
        channel.setMethodCallHandler(null)
    }
}
