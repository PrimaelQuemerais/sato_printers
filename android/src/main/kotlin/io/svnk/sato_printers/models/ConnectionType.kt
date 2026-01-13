package io.svnk.sato_printers.models

/**
 * Represents the type of connection to establish with a SATO printer.
 */
enum class ConnectionType {
    BLUETOOTH,
    TCP,
    USB;

    companion object {
        fun fromString(value: String): ConnectionType {
            return when (value.uppercase()) {
                "BLUETOOTH" -> BLUETOOTH
                "TCP" -> TCP
                "USB" -> USB
                else -> throw IllegalArgumentException("Unknown connection type: $value")
            }
        }
    }

    fun toMap(): String = name.lowercase()
}

