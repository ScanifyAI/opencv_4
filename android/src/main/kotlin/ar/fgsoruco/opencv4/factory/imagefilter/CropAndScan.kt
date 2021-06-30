package ar.fgsoruco.opencv4.factory.imagefilter


import android.R.attr.bitmap
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.ByteArrayOutputStream


class CropAndScan {
    companion object {
        fun process(pathString: String, tl_x: Double, tl_y: Double, tr_x: Double, tr_y: Double, bl_x: Double, bl_y: Double, br_x: Double, br_y: Double, result: MethodChannel.Result) {

            try {

                if (OpenCVLoader.initDebug()) {
                    println("LOGX ==> Init Opencv")
                    var bitmap = BitmapFactory.decodeFile(pathString)
                    val height: Int = bitmap.getHeight()
                    val width: Int = bitmap.getWidth()
                    val mat = Mat()
                    Utils.bitmapToMat(bitmap, mat)
                    Imgproc.cvtColor(mat, mat, Imgproc.COLOR_BGR2GRAY)

                    Imgproc.GaussianBlur(mat, mat, Size(5.0, 5.0), 0.0)
                    val src_mat = Mat(4, 1, CvType.CV_32FC2)
                    val dst_mat = Mat(4, 1, CvType.CV_32FC2)
   
                    src_mat.put(0, 0, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y)
                    dst_mat.put(0, 0, 0.0, 0.0, width.toDouble(), 0.0, 0.0, height.toDouble(), width.toDouble(), height.toDouble())
                    val perspectiveTransform = Imgproc.getPerspectiveTransform(src_mat, dst_mat)

                    Imgproc.warpPerspective(mat, mat, perspectiveTransform, Size(width.toDouble(), height.toDouble()))

                    Imgproc.adaptiveThreshold(mat, mat, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 401, 14.0)
                    val blurred = Mat()
                    Imgproc.GaussianBlur(mat, blurred, Size(5.0, 5.0), 0.0)
                    val result1 = Mat()
                    Core.addWeighted(blurred, 0.5, mat, 0.5, 1.0, result1)

                    Utils.matToBitmap(result1, bitmap)
                    bitmap = Bitmap.createScaledBitmap(bitmap, 2480, 3508, true)
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                    val byteArray = stream.toByteArray()
                    println("LOGX ==>  Finish!! ")
                    result.success(byteArray)
                }

                result.success(null)
            } catch (e: java.lang.Exception) {
                println("LOGX ==>  CropToScan PROCESS: $e")
                return
            }
        }

    }
}