package io.svnk.sato_printers.models

/**
 * Options for print operations.
 */
data class PrintOptions(
    val copies: Int = 1,
    val timeout: Int = 10000,
    val expectResponse: Boolean = false,
    val responseByteCount: Int = -1,
    val responseTerminator: ByteArray? = null
) {
    companion object {
        fun fromMap(map: Map<String, Any?>?): PrintOptions {
            if (map == null) return PrintOptions()

            return PrintOptions(
                copies = (map["copies"] as? Int) ?: 1,
                timeout = (map["timeout"] as? Int) ?: 10000,
                expectResponse = (map["expectResponse"] as? Boolean) ?: false,
                responseByteCount = (map["responseByteCount"] as? Int) ?: -1,
                responseTerminator = (map["responseTerminator"] as? ByteArray)
            )
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as PrintOptions

        if (copies != other.copies) return false
        if (timeout != other.timeout) return false
        if (expectResponse != other.expectResponse) return false
        if (responseByteCount != other.responseByteCount) return false
        if (responseTerminator != null) {
            if (other.responseTerminator == null) return false
            if (!responseTerminator.contentEquals(other.responseTerminator)) return false
        } else if (other.responseTerminator != null) return false

        return true
    }

    override fun hashCode(): Int {
        var result = copies
        result = 31 * result + timeout
        result = 31 * result + expectResponse.hashCode()
        result = 31 * result + responseByteCount
        result = 31 * result + (responseTerminator?.contentHashCode() ?: 0)
        return result
    }
}

