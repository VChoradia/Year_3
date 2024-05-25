package com.example.shopping_todo_list

import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.shopping_todo_list.ui.add_edit_todo.AddEditToDoScreen
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented test, which will execute on an Android device.
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {
    @Test
    fun useAppContext() {
        // Context of the app under test.
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.example.shopping_todo_list", appContext.packageName)
    }
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testCreateTodoItem() {
        composeTestRule.setContent {
            AddEditToDoScreen(onPopBackStack = { /* Define action to pop back stack */ })
        }

        // Find and interact with the UI elements to create a ToDo
        composeTestRule.onNode(hasText("Title"))
            .performTextInput("ToDo Title")

        composeTestRule.onNode(hasText("Description"))
            .performTextInput("ToDo Description")

        // ... add interactions for other fields if applicable

        composeTestRule.onNodeWithText("Save")
            .performClick()

        composeTestRule.onNode(hasText("ToDo Title")).assertExists()
        composeTestRule.onNode(hasText("ToDo Description")).assertExists()
    }
}