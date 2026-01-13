package io.svnk.sato_printers.models

/**
 * Represents a discovered SATO printer device.
 */
data class PrinterDevice(
    val name: String?,
    val address: String,
    val connectionType: ConnectionType,
    val serialNumber: String? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "name" to name,
            "address" to address,
            "connectionType" to connectionType.toMap(),
            "serialNumber" to serialNumber
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): PrinterDevice {
            return PrinterDevice(
                name = map["name"] as? String,
                address = map["address"] as String,
                connectionType = ConnectionType.fromString(map["connectionType"] as String),
                serialNumber = map["serialNumber"] as? String
            )
        }
    }
}

