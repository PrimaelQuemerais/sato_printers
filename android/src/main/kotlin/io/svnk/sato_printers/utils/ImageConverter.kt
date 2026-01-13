package io.svnk.sato_printers.utils

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import java.io.ByteArrayOutputStream

/**
 * Utility class for converting images to SATO printer format.
 * SATO printers typically use SBPL (SATO Barcode Printer Language) commands.
 */
object ImageConverter {

    /**
     * Converts image bytes to a monochrome bitmap suitable for label printing.
     *
     * @param imageBytes The source image data
     * @param targetWidth Optional target width in pixels
     * @param targetHeight Optional target height in pixels
     * @param threshold Threshold for converting to black/white (0-255)
     * @return ByteArray containing the converted image data
     */
    fun convertToMonochrome(
        imageBytes: ByteArray,
        targetWidth: Int? = null,
        targetHeight: Int? = null,
        threshold: Int = 128
    ): ByteArray {
        // Decode the image
        var bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            ?: throw IllegalArgumentException("Failed to decode image")

        // Resize if dimensions are specified
        if (targetWidth != null && targetHeight != null) {
            bitmap = Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
        }

        val width = bitmap.width
        val height = bitmap.height

        // Create monochrome bitmap
        val monoBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = bitmap.getPixel(x, y)
                val red = Color.red(pixel)
                val green = Color.green(pixel)
                val blue = Color.blue(pixel)

                // Convert to grayscale using luminosity method
                val gray = (0.299 * red + 0.587 * green + 0.114 * blue).toInt()

                // Apply threshold
                val monoColor = if (gray < threshold) Color.BLACK else Color.WHITE
                monoBitmap.setPixel(x, y, monoColor)
            }
        }

        // Convert to PNG byte array
        val outputStream = ByteArrayOutputStream()
        monoBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        return outputStream.toByteArray()
    }

    /**
     * Converts image bytes to raw bitmap data (1-bit per pixel).
     * This format is typically required by thermal label printers.
     *
     * @param imageBytes The source image data
     * @param threshold Threshold for converting to black/white (0-255)
     * @return ByteArray containing 1-bit bitmap data
     */
    fun convertToRawBitmap(
        imageBytes: ByteArray,
        threshold: Int = 128
    ): ByteArray {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            ?: throw IllegalArgumentException("Failed to decode image")

        val width = bitmap.width
        val height = bitmap.height

        // Width must be padded to byte boundary (8 pixels)
        val paddedWidth = ((width + 7) / 8) * 8
        val bytesPerRow = paddedWidth / 8

        val rawData = ByteArray(bytesPerRow * height)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = bitmap.getPixel(x, y)
                val red = Color.red(pixel)
                val green = Color.green(pixel)
                val blue = Color.blue(pixel)

                // Convert to grayscale
                val gray = (0.299 * red + 0.587 * green + 0.114 * blue).toInt()

                // If pixel is dark, set the bit
                if (gray < threshold) {
                    val byteIndex = y * bytesPerRow + x / 8
                    val bitIndex = 7 - (x % 8)
                    rawData[byteIndex] = (rawData[byteIndex].toInt() or (1 shl bitIndex)).toByte()
                }
            }
        }

        return rawData
    }

    /**
     * Wraps raw bitmap data with SBPL graphic commands.
     * This creates a complete print command for SATO printers.
     *
     * @param rawBitmapData The raw 1-bit bitmap data
     * @param width Image width in pixels
     * @param height Image height in pixels
     * @param xPosition X position on the label
     * @param yPosition Y position on the label
     * @return ByteArray containing SBPL commands with graphic data
     */
    fun wrapWithSbplGraphicCommand(
        rawBitmapData: ByteArray,
        width: Int,
        height: Int,
        xPosition: Int = 0,
        yPosition: Int = 0
    ): ByteArray {
        val output = ByteArrayOutputStream()

        // STX - Start of text
        output.write(0x02)

        // Set horizontal position
        output.write("H${String.format("%04d", xPosition)}".toByteArray())

        // Set vertical position
        output.write("V${String.format("%04d", yPosition)}".toByteArray())

        // Graphic command
        // GH - Graphic with height specification
        val bytesPerRow = ((width + 7) / 8)
        output.write("GH${String.format("%03d", bytesPerRow)}${String.format("%03d", height)}".toByteArray())

        // Write the bitmap data
        output.write(rawBitmapData)

        // Print command
        output.write("Q1".toByteArray())

        // ETX - End of text
        output.write(0x03)

        return output.toByteArray()
    }

    /**
     * Gets image dimensions without fully decoding the image.
     *
     * @param imageBytes The image data
     * @return Pair of width and height
     */
    fun getImageDimensions(imageBytes: ByteArray): Pair<Int, Int> {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, options)
        return Pair(options.outWidth, options.outHeight)
    }
}

