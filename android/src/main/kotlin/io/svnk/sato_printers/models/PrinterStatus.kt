package io.svnk.sato_printers.models

/**
 * Represents the status of a SATO printer.
 */
data class PrinterStatusInfo(
    val isConnected: Boolean,
    val isOnline: Boolean = false,
    val isPaperOut: Boolean = false,
    val isRibbonOut: Boolean = false,
    val isCoverOpen: Boolean = false,
    val hasError: Boolean = false,
    val errorMessage: String? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "isConnected" to isConnected,
            "isOnline" to isOnline,
            "isPaperOut" to isPaperOut,
            "isRibbonOut" to isRibbonOut,
            "isCoverOpen" to isCoverOpen,
            "hasError" to hasError,
            "errorMessage" to errorMessage
        )
    }
}

