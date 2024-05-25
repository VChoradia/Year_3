package com.example.shopping_todo_list.ui.budget_page

import android.graphics.Color
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import android.graphics.Paint
import android.graphics.PointF
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.remember
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

/*
    Adopted from https://github.com/aqua30/GraphCompose/blob/master/app/src/main/java/com/aqua30/graphcompose/screen/Graph.kt
    Author: Saurabh (aqua30)
    Adopted by: BSc Team 06
     */
@Composable
fun BudgetGraph(
    viewModel: BudgetPageViewModel = hiltViewModel()
) {
    val monthlySpendings = viewModel.monthlySpendings
    val maxSpending = monthlySpendings.maxOfOrNull { it.value.toFloat() } ?: 0f

    // Calculate yStep based on the highest spending value
    val yStep = if (maxSpending > 0) (maxSpending / 5).toInt() else 100

    val monthLabels = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

    // Use the spending values for the graph
    val points = (1..12).map { month ->
        monthlySpendings[month]?.toFloat() ?: 0f
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Graph(
            modifier = Modifier
                .width(450.dp)
                .height(400.dp),
            xValues = monthLabels,
            yValues = (0..6).map { (it + 1) * yStep },
            points = points,
            paddingSpace = 16.dp,
            verticalStep = yStep
        )
    }
}

@Composable
fun Graph(
    modifier: Modifier,
    xValues: List<String>,
    yValues: List<Int>,
    points: List<Float>,
    paddingSpace: Dp,
    verticalStep: Int
) {
    val controlPoints1 = mutableListOf<PointF>()
    val controlPoints2 = mutableListOf<PointF>()
    val coordinates = mutableListOf<PointF>()
    val density = LocalDensity.current
    val textPaint = remember(density) {
        Paint().apply {
            color = Color.BLACK
            textAlign = Paint.Align.CENTER
            textSize = density.run { 12.sp.toPx() }
        }
    }

    Box(
        modifier = modifier
            .background(androidx.compose.ui.graphics.Color.White)
            .padding(horizontal = 8.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(
            modifier = Modifier.fillMaxSize(),
        ) {
            val xAxisSpace = (size.width - paddingSpace.toPx()) / xValues.size
            val yAxisSpace = size.height / yValues.size

            // Placing x axis points
            for (i in xValues.indices) {
                drawContext.canvas.nativeCanvas.drawText(
                    xValues[i],
                    xAxisSpace * (i + 1),
                    size.height - 30,
                    textPaint
                )
            }

            // Placing y axis points
            for (i in yValues.indices) {
                drawContext.canvas.nativeCanvas.drawText(
                    "${yValues[i]}",
                    paddingSpace.toPx() / 2f,
                    size.height - yAxisSpace * (i + 1),
                    textPaint
                )
            }

            // Placing our x axis points
            for (i in points.indices) {
                val x1 = xAxisSpace * (i + 1)
                val y1 = size.height - (yAxisSpace * (points[i] / verticalStep.toFloat()))
                coordinates.add(PointF(x1, y1))
                drawCircle(
                    color = androidx.compose.ui.graphics.Color.Red,
                    radius = 12f,
                    center = Offset(x1, y1)
                )
            }

            // Calculating the connection points with more control
            for (i in 1 until coordinates.size) {
                controlPoints1.add(PointF(coordinates[i - 1].x + xAxisSpace / 2, coordinates[i - 1].y))
                controlPoints2.add(PointF(coordinates[i].x - xAxisSpace / 2, coordinates[i].y))
            }

            // Drawing the path
            val stroke = Path().apply {
                reset()
                moveTo(coordinates.first().x, coordinates.first().y)
                for (i in 0 until 11) {
                    cubicTo(
                        controlPoints1[i].x, controlPoints1[i].y,
                        controlPoints2[i].x, controlPoints2[i].y,
                        coordinates[i + 1].x, coordinates[i + 1].y
                    )
                }
            }

            // Filling the area under the path
            val fillPath = android.graphics.Path(stroke.asAndroidPath())
                .asComposePath()
                .apply {
                    lineTo(xAxisSpace * xValues.size, size.height - yAxisSpace)
                    lineTo(xAxisSpace, size.height - yAxisSpace)
                    close()
                }

            drawPath(
                fillPath,
                brush = Brush.verticalGradient(
                    listOf(
                        androidx.compose.ui.graphics.Color.Blue,
                        androidx.compose.ui.graphics.Color.Transparent,
                    ),
                    endY = size.height - yAxisSpace
                ),
            )

            drawPath(
                stroke,
                color = androidx.compose.ui.graphics.Color.DarkGray,
                style = Stroke(
                    width = 3f,
                    cap = StrokeCap.Round
                )
            )
        }
    }
}
