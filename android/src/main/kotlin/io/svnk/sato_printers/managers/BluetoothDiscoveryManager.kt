package io.svnk.sato_printers.managers

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import io.svnk.sato_printers.models.ConnectionType
import io.svnk.sato_printers.models.PrinterDevice

/**
 * Manages Bluetooth device discovery for SATO printers.
 */
class BluetoothDiscoveryManager(private val context: Context) {

    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    /**
     * Checks if Bluetooth is available on the device.
     */
    fun isBluetoothAvailable(): Boolean {
        return bluetoothAdapter != null
    }

    /**
     * Checks if Bluetooth is enabled.
     */
    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    /**
     * Gets the list of paired/bonded Bluetooth devices.
     * These are devices that have been previously paired with the Android device.
     */
    fun getPairedDevices(): List<PrinterDevice> {
        if (!isBluetoothAvailable() || !isBluetoothEnabled()) {
            return emptyList()
        }

        val bondedDevices: Set<BluetoothDevice>? = try {
            bluetoothAdapter?.bondedDevices
        } catch (e: SecurityException) {
            // Bluetooth permission not granted
            null
        }

        return bondedDevices?.map { device ->
            PrinterDevice(
                name = try { device.name } catch (e: SecurityException) { null },
                address = device.address,
                connectionType = ConnectionType.BLUETOOTH
            )
        } ?: emptyList()
    }

    /**
     * Gets a specific Bluetooth device by address.
     */
    fun getDeviceByAddress(address: String): BluetoothDevice? {
        return try {
            bluetoothAdapter?.getRemoteDevice(address)
        } catch (e: Exception) {
            null
        }
    }
}

