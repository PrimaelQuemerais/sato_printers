package io.svnk.sato_printers.handlers

import io.flutter.plugin.common.MethodChannel.Result
import io.svnk.sato_printers.managers.PrinterManager
import io.svnk.sato_printers.utils.ErrorMapper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Handles printer connection operations.
 */
class ConnectionHandler(private val printerManager: PrinterManager) {

    private val scope = CoroutineScope(Dispatchers.Main)

    /**
     * Connects to a Bluetooth printer.
     *
     * @param address The Bluetooth MAC address
     * @param timeout Connection timeout in milliseconds
     * @param result The method channel result
     */
    fun connectBluetooth(address: String, timeout: Int, result: Result) {
        scope.launch {
            try {
                val success = withContext(Dispatchers.IO) {
                    printerManager.connectBluetooth(address, timeout)
                }
                result.success(success)
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Connects to a TCP/IP printer.
     *
     * @param ipAddress The IP address
     * @param port The TCP port
     * @param timeout Connection timeout in milliseconds
     * @param result The method channel result
     */
    fun connectTcp(ipAddress: String, port: Int, timeout: Int, result: Result) {
        scope.launch {
            try {
                val success = withContext(Dispatchers.IO) {
                    printerManager.connectTcp(ipAddress, port, timeout)
                }
                result.success(success)
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Connects to a USB printer.
     *
     * @param serialNumber The USB serial number
     * @param result The method channel result
     */
    fun connectUsb(serialNumber: String, result: Result) {
        scope.launch {
            try {
                val success = withContext(Dispatchers.IO) {
                    printerManager.connectUsb(serialNumber)
                }
                result.success(success)
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Disconnects from the current printer.
     *
     * @param result The method channel result
     */
    fun disconnect(result: Result) {
        scope.launch {
            try {
                val success = withContext(Dispatchers.IO) {
                    printerManager.disconnect()
                }
                result.success(success)
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Checks if a printer is currently connected.
     *
     * @param result The method channel result
     */
    fun isConnected(result: Result) {
        result.success(printerManager.isConnected())
    }

    /**
     * Gets the currently connected device info.
     *
     * @param result The method channel result
     */
    fun getCurrentDevice(result: Result) {
        val device = printerManager.getCurrentDevice()
        result.success(device?.toMap())
    }
}

