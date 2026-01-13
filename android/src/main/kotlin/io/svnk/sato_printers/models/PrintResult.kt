package io.svnk.sato_printers.models

/**
 * Represents the result of a print operation.
 */
data class PrintResult(
    val success: Boolean,
    val message: String? = null,
    val responseData: ByteArray? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "success" to success,
            "message" to message,
            "responseData" to responseData
        )
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as PrintResult

        if (success != other.success) return false
        if (message != other.message) return false
        if (responseData != null) {
            if (other.responseData == null) return false
            if (!responseData.contentEquals(other.responseData)) return false
        } else if (other.responseData != null) return false

        return true
    }

    override fun hashCode(): Int {
        var result = success.hashCode()
        result = 31 * result + (message?.hashCode() ?: 0)
        result = 31 * result + (responseData?.contentHashCode() ?: 0)
        return result
    }
}

