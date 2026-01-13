package io.svnk.sato_printers.utils

import jp.co.sato.android.printer.PrinterErrorException
import jp.co.sato.android.printer.ReadTimeoutException
import java.io.IOException

/**
 * Utility class for mapping SDK errors to plugin-specific error codes.
 */
object ErrorMapper {

    object ErrorCodes {
        const val UNKNOWN = "UNKNOWN_ERROR"
        const val CONNECTION_FAILED = "CONNECTION_FAILED"
        const val NOT_CONNECTED = "NOT_CONNECTED"
        const val BLUETOOTH_DISABLED = "BLUETOOTH_DISABLED"
        const val BLUETOOTH_UNAVAILABLE = "BLUETOOTH_UNAVAILABLE"
        const val PERMISSION_DENIED = "PERMISSION_DENIED"
        const val TIMEOUT = "TIMEOUT"
        const val IO_ERROR = "IO_ERROR"
        const val PRINTER_ERROR = "PRINTER_ERROR"
        const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
        const val DEVICE_NOT_FOUND = "DEVICE_NOT_FOUND"
    }

    /**
     * Maps an exception to an error code and message.
     *
     * @param exception The exception to map
     * @return Pair of error code and error message
     */
    fun mapException(exception: Exception): Pair<String, String> {
        return when (exception) {
            is ReadTimeoutException -> Pair(
                ErrorCodes.TIMEOUT,
                "Communication timeout: ${exception.message ?: "No response from printer"}"
            )
            is PrinterErrorException -> Pair(
                ErrorCodes.PRINTER_ERROR,
                "Printer error: ${exception.message ?: "Unknown printer error"}"
            )
            is IOException -> Pair(
                ErrorCodes.IO_ERROR,
                "Communication error: ${exception.message ?: "Unknown IO error"}"
            )
            is SecurityException -> Pair(
                ErrorCodes.PERMISSION_DENIED,
                "Permission denied: ${exception.message ?: "Required permission not granted"}"
            )
            is IllegalArgumentException -> Pair(
                ErrorCodes.INVALID_ARGUMENT,
                "Invalid argument: ${exception.message ?: "Invalid parameter provided"}"
            )
            is IllegalStateException -> Pair(
                ErrorCodes.NOT_CONNECTED,
                "Invalid state: ${exception.message ?: "Printer not in expected state"}"
            )
            else -> Pair(
                ErrorCodes.UNKNOWN,
                "Unknown error: ${exception.message ?: exception.javaClass.simpleName}"
            )
        }
    }

    /**
     * Creates a standardized error map for Flutter method channel responses.
     *
     * @param errorCode The error code
     * @param message The error message
     * @param details Optional additional details
     * @return Map containing error information
     */
    fun createErrorMap(
        errorCode: String,
        message: String,
        details: Any? = null
    ): Map<String, Any?> {
        return mapOf(
            "errorCode" to errorCode,
            "message" to message,
            "details" to details
        )
    }
}

