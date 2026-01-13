package io.svnk.sato_printers.handlers

import android.content.Context
import io.flutter.plugin.common.MethodChannel.Result
import io.svnk.sato_printers.managers.BluetoothDiscoveryManager
import io.svnk.sato_printers.managers.UsbDiscoveryManager
import io.svnk.sato_printers.utils.ErrorMapper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Handles printer discovery operations.
 */
class DiscoveryHandler(context: Context) {

    private val bluetoothDiscoveryManager = BluetoothDiscoveryManager(context)
    private val usbDiscoveryManager = UsbDiscoveryManager(context)
    private val scope = CoroutineScope(Dispatchers.Main)

    /**
     * Discovers paired Bluetooth printers.
     */
    fun discoverBluetoothPrinters(result: Result) {
        scope.launch {
            try {
                if (!bluetoothDiscoveryManager.isBluetoothAvailable()) {
                    result.error(
                        ErrorMapper.ErrorCodes.BLUETOOTH_UNAVAILABLE,
                        "Bluetooth is not available on this device",
                        null
                    )
                    return@launch
                }

                if (!bluetoothDiscoveryManager.isBluetoothEnabled()) {
                    result.error(
                        ErrorMapper.ErrorCodes.BLUETOOTH_DISABLED,
                        "Bluetooth is not enabled",
                        null
                    )
                    return@launch
                }

                val devices = withContext(Dispatchers.IO) {
                    bluetoothDiscoveryManager.getPairedDevices()
                }

                result.success(devices.map { it.toMap() })
            } catch (e: SecurityException) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Discovers connected USB printers.
     */
    fun discoverUsbPrinters(result: Result) {
        scope.launch {
            try {
                val devices = withContext(Dispatchers.IO) {
                    usbDiscoveryManager.getConnectedDevices()
                }

                result.success(devices.map { it.toMap() })
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Checks if Bluetooth is available and enabled.
     */
    fun checkBluetoothStatus(result: Result) {
        val status = mapOf(
            "available" to bluetoothDiscoveryManager.isBluetoothAvailable(),
            "enabled" to bluetoothDiscoveryManager.isBluetoothEnabled()
        )
        result.success(status)
    }
}

