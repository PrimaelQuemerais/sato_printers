package io.svnk.sato_printers.handlers

import android.util.Log
import io.flutter.plugin.common.MethodChannel.Result
import io.svnk.sato_printers.managers.PrinterManager
import io.svnk.sato_printers.models.PrintOptions
import io.svnk.sato_printers.utils.ErrorMapper
import io.svnk.sato_printers.utils.ImageConverter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Handles print operations.
 */
class PrintHandler(private val printerManager: PrinterManager) {

    companion object {
        private const val TAG = "SatoPrintHandler"
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    /**
     * Sends raw data to the printer.
     *
     * @param data The raw data bytes
     * @param options Print options map
     * @param result The method channel result
     */
    fun printRawData(data: ByteArray, options: Map<String, Any?>?, result: Result) {
        Log.d(TAG, "printRawData: Received ${data.size} bytes to print")
        Log.d(TAG, "printRawData: Options = $options")

        scope.launch {
            try {
                val printOptions = PrintOptions.fromMap(options)
                Log.d(TAG, "printRawData: Parsed options - expectResponse=${printOptions.expectResponse}, timeout=${printOptions.timeout}")

                val printResult = withContext(Dispatchers.IO) {
                    Log.d(TAG, "printRawData: Calling printerManager.sendRawData on IO thread")
                    printerManager.sendRawData(data, printOptions)
                }

                Log.d(TAG, "printRawData: Result - success=${printResult.success}, message=${printResult.message}")
                if (printResult.responseData != null) {
                    Log.d(TAG, "printRawData: Response data size = ${printResult.responseData.size}")
                }

                result.success(printResult.toMap())
            } catch (e: Exception) {
                Log.e(TAG, "printRawData: Exception occurred", e)
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Prints an image.
     *
     * @param imageBytes The image data
     * @param options Print options map including positioning and formatting
     * @param result The method channel result
     */
    fun printImage(imageBytes: ByteArray, options: Map<String, Any?>?, result: Result) {
        scope.launch {
            try {
                val printOptions = PrintOptions.fromMap(options)
                val xPosition = (options?.get("xPosition") as? Int) ?: 0
                val yPosition = (options?.get("yPosition") as? Int) ?: 0
                val convertToSbpl = (options?.get("convertToSbpl") as? Boolean) ?: true

                val dataToSend = if (convertToSbpl) {
                    withContext(Dispatchers.Default) {
                        // Get image dimensions
                        val (width, height) = ImageConverter.getImageDimensions(imageBytes)

                        // Convert to raw bitmap
                        val rawBitmap = ImageConverter.convertToRawBitmap(imageBytes)

                        // Wrap with SBPL commands
                        ImageConverter.wrapWithSbplGraphicCommand(
                            rawBitmap,
                            width,
                            height,
                            xPosition,
                            yPosition
                        )
                    }
                } else {
                    imageBytes
                }

                val printResult = withContext(Dispatchers.IO) {
                    printerManager.sendRawData(dataToSend, printOptions)
                }
                result.success(printResult.toMap())
            } catch (e: Exception) {
                val (code, message) = ErrorMapper.mapException(e)
                result.error(code, message, null)
            }
        }
    }

    /**
     * Gets the printer status.
     *
     * @param result The method channel result
     */
    fun getStatus(result: Result) {
        try {
            val status = printerManager.getStatus()
            result.success(status.toMap())
        } catch (e: Exception) {
            val (code, message) = ErrorMapper.mapException(e)
            result.error(code, message, null)
        }
    }

    /**
     * Sets the read timeout.
     *
     * @param timeout Timeout in milliseconds
     * @param result The method channel result
     */
    fun setReadTimeout(timeout: Int, result: Result) {
        try {
            printerManager.setReadTimeout(timeout)
            result.success(true)
        } catch (e: Exception) {
            val (code, message) = ErrorMapper.mapException(e)
            result.error(code, message, null)
        }
    }
}

