package io.svnk.sato_printers.managers

import android.content.Context
import android.hardware.usb.UsbDevice
import io.svnk.sato_printers.models.ConnectionType
import io.svnk.sato_printers.models.PrinterDevice
import jp.co.sato.android.printer.UsbFinder

/**
 * Manages USB device discovery for SATO printers.
 */
class UsbDiscoveryManager(private val context: Context) {

    private val usbFinder: UsbFinder = UsbFinder(context)

    /**
     * Gets the list of connected USB SATO printers.
     */
    fun getConnectedDevices(): List<PrinterDevice> {
        val connectedDevices: Set<UsbDevice>? = usbFinder.connectedDevices

        return connectedDevices?.mapNotNull { device ->
            val serialNumber = device.serialNumber ?: return@mapNotNull null
            PrinterDevice(
                name = device.productName,
                address = serialNumber,
                connectionType = ConnectionType.USB,
                serialNumber = serialNumber
            )
        } ?: emptyList()
    }

    /**
     * Gets a specific USB device by serial number.
     */
    fun getDeviceBySerialNumber(serialNumber: String): UsbDevice? {
        return usbFinder.connectedDevices?.find {
            it.serialNumber == serialNumber
        }
    }

    /**
     * Checks if USB is available.
     */
    fun isUsbAvailable(): Boolean {
        return true // USB is always available on Android
    }
}

