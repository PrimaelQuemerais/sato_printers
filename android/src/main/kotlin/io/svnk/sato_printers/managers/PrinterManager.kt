package io.svnk.sato_printers.managers

import android.content.Context
import io.svnk.sato_printers.models.*
import jp.co.sato.android.printer.BluetoothPrinter
import jp.co.sato.android.printer.Printer
import jp.co.sato.android.printer.PrinterProtocolType
import jp.co.sato.android.printer.ReadTimeoutException
import jp.co.sato.android.printer.TcpPrinter
import jp.co.sato.android.printer.UsbPrinter
import java.io.IOException

/**
 * Manages SATO printer connections and operations.
 * This is the central manager that handles all printer interactions.
 */
class PrinterManager(private val context: Context) {

    companion object {
        private const val TAG = "SatoPrinterManager"
        private const val DEFAULT_CONNECT_TIMEOUT = 10000 // 10 seconds
        private const val DEFAULT_READ_TIMEOUT = 10000 // 10 seconds
    }

    private var currentPrinter: Printer? = null
    private var currentDevice: PrinterDevice? = null

    /**
     * Connects to a Bluetooth printer.
     *
     * @param address The Bluetooth MAC address of the printer
     * @param timeout Connection timeout in milliseconds
     * @return true if connection was successful
     */
    @Throws(IOException::class)
    fun connectBluetooth(address: String, timeout: Int = DEFAULT_CONNECT_TIMEOUT): Boolean {
        android.util.Log.d(TAG, "connectBluetooth: Starting connection to $address with timeout $timeout")
        disconnect()

        val printer = BluetoothPrinter(
            address,
            PrinterProtocolType.NONE,
            false,
            timeout
        )
        android.util.Log.d(TAG, "connectBluetooth: BluetoothPrinter created, setting read timeout")
        printer.readTimeout = DEFAULT_READ_TIMEOUT
        android.util.Log.d(TAG, "connectBluetooth: Calling printer.connect()...")
        printer.connect()
        android.util.Log.d(TAG, "connectBluetooth: Connection successful, isConnected=${printer.isConnected}")

        currentPrinter = printer
        currentDevice = PrinterDevice(
            name = null,
            address = address,
            connectionType = ConnectionType.BLUETOOTH
        )
        return true
    }

    /**
     * Connects to a TCP/IP printer.
     *
     * @param ipAddress The IP address of the printer
     * @param port The TCP port (usually 9100)
     * @param timeout Connection timeout in milliseconds
     * @return true if connection was successful
     */
    @Throws(IOException::class)
    fun connectTcp(ipAddress: String, port: Int, timeout: Int = DEFAULT_CONNECT_TIMEOUT): Boolean {
        android.util.Log.d(TAG, "connectTcp: Starting connection to $ipAddress:$port with timeout $timeout")
        disconnect()

        val printer = TcpPrinter(
            ipAddress,
            port,
            PrinterProtocolType.NONE,
            false,
            timeout
        )
        android.util.Log.d(TAG, "connectTcp: TcpPrinter created, setting read timeout")
        printer.readTimeout = DEFAULT_READ_TIMEOUT
        android.util.Log.d(TAG, "connectTcp: Calling printer.connect()...")
        printer.connect()
        android.util.Log.d(TAG, "connectTcp: Connection successful, isConnected=${printer.isConnected}")

        currentPrinter = printer
        currentDevice = PrinterDevice(
            name = null,
            address = "$ipAddress:$port",
            connectionType = ConnectionType.TCP
        )
        return true
    }

    /**
     * Connects to a USB printer.
     *
     * @param serialNumber The USB serial number of the printer
     * @return true if connection was successful
     */
    @Throws(IOException::class)
    fun connectUsb(serialNumber: String): Boolean {
        disconnect()

        val printer = UsbPrinter(
            context,
            serialNumber,
            PrinterProtocolType.NONE,
            false
        )
        printer.readTimeout = DEFAULT_READ_TIMEOUT
        printer.connect()

        currentPrinter = printer
        currentDevice = PrinterDevice(
            name = null,
            address = serialNumber,
            connectionType = ConnectionType.USB,
            serialNumber = serialNumber
        )
        return true
    }

    /**
     * Disconnects from the current printer.
     */
    fun disconnect(): Boolean {
        try {
            currentPrinter?.close()
        } catch (e: Exception) {
            // Ignore close errors
        } finally {
            currentPrinter = null
            currentDevice = null
        }
        return true
    }

    /**
     * Checks if a printer is currently connected.
     */
    fun isConnected(): Boolean {
        return currentPrinter?.isConnected == true
    }

    /**
     * Gets the currently connected device info.
     */
    fun getCurrentDevice(): PrinterDevice? {
        return currentDevice
    }

    /**
     * Sends raw data to the printer.
     *
     * @param data The raw data to send
     * @param options Print options including response handling
     * @return PrintResult containing success status and any response data
     */
    @Throws(IOException::class, ReadTimeoutException::class)
    fun sendRawData(data: ByteArray, options: PrintOptions = PrintOptions()): PrintResult {
        android.util.Log.d(TAG, "sendRawData: Starting with ${data.size} bytes")
        android.util.Log.d(TAG, "sendRawData: Data hex: ${data.joinToString(" ") { String.format("%02X", it) }}")
        android.util.Log.d(TAG, "sendRawData: Options - expectResponse=${options.expectResponse}, timeout=${options.timeout}, responseByteCount=${options.responseByteCount}")

        val printer = currentPrinter
            ?: throw IOException("No printer connected")

        android.util.Log.d(TAG, "sendRawData: Printer instance found, checking connection...")

        if (!printer.isConnected) {
            android.util.Log.d(TAG, "sendRawData: Printer not connected, attempting to reconnect...")
            printer.connect()
            android.util.Log.d(TAG, "sendRawData: Reconnection successful")
        } else {
            android.util.Log.d(TAG, "sendRawData: Printer is connected")
        }

        return try {
            // Set the read timeout if specified
            printer.readTimeout = options.timeout
            android.util.Log.d(TAG, "sendRawData: Read timeout set to ${options.timeout}ms")

            // Send data and optionally receive response
            android.util.Log.d(TAG, "sendRawData: Calling printer.writeData()...")
            val responseData = if (options.expectResponse) {
                android.util.Log.d(TAG, "sendRawData: Expecting response - responseByteCount=${options.responseByteCount}")
                printer.writeData(
                    data,
                    options.responseByteCount,
                    options.responseTerminator ?: ByteArray(0)
                )
            } else {
                android.util.Log.d(TAG, "sendRawData: Not expecting response, using -1 for byte count")
                printer.writeData(data, -1, ByteArray(0))
                null
            }

            android.util.Log.d(TAG, "sendRawData: writeData completed successfully")
            if (responseData != null) {
                android.util.Log.d(TAG, "sendRawData: Response received: ${responseData.size} bytes")
                android.util.Log.d(TAG, "sendRawData: Response hex: ${responseData.joinToString(" ") { String.format("%02X", it) }}")
            }

            PrintResult(
                success = true,
                message = "Data sent successfully",
                responseData = responseData
            )
        } catch (e: ReadTimeoutException) {
            android.util.Log.e(TAG, "sendRawData: Read timeout exception", e)
            PrintResult(
                success = false,
                message = "Read timeout: ${e.message}"
            )
        } catch (e: IOException) {
            android.util.Log.e(TAG, "sendRawData: IO exception", e)
            PrintResult(
                success = false,
                message = "IO error: ${e.message}"
            )
        } catch (e: Exception) {
            android.util.Log.e(TAG, "sendRawData: Unexpected exception", e)
            PrintResult(
                success = false,
                message = "Unexpected error: ${e.message}"
            )
        }
    }

    /**
     * Prints an image by converting it to printer format and sending.
     * Note: The actual image conversion logic will depend on the printer model
     * and the SBPL (SATO Barcode Printer Language) commands required.
     *
     * @param imageBytes The image data as a byte array
     * @param options Print options
     * @return PrintResult containing success status
     */
    @Throws(IOException::class)
    fun printImage(imageBytes: ByteArray, options: PrintOptions = PrintOptions()): PrintResult {
        val printer = currentPrinter
            ?: throw IOException("No printer connected")

        if (!printer.isConnected) {
            printer.connect()
        }

        // For now, we'll send the image bytes directly
        // In a full implementation, you would convert the image to SBPL commands
        // using ImageConverter utility class
        return sendRawData(imageBytes, options)
    }

    /**
     * Gets the current printer status.
     * Note: Status retrieval depends on the printer model and may not be available
     * on all connection types.
     */
    fun getStatus(): PrinterStatusInfo {
        val printer = currentPrinter
        val isConnected = printer?.isConnected == true

        return PrinterStatusInfo(
            isConnected = isConnected,
            isOnline = isConnected,
            hasError = false
        )
    }

    /**
     * Sets the read timeout for printer responses.
     */
    fun setReadTimeout(timeout: Int) {
        currentPrinter?.readTimeout = timeout
    }
}

